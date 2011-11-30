module Ubiquo
  module Helpers

    # Form Builder that allows to dry our ubiquo forms. It is used by
    # #ubiquo_form_for, but can be used with:
    #
    #   form_for( @actor, :builder => Ubiquo::Helpers::UbiquoFormBuider )
    #
    # How to add methods from the plugins?
    #   the media_selector for instance has to:
    #   1. Add the methods to the global form helper as usual
    #   2. Update UbiquoFormBuilder attributes
    #
    #   The UbiquoFormBuilder becomes proxy of all the FormBuilder methods for
    #   input fields (#text_field, #select_field, #date_select, etc.)
    #
    #   We add a wrapper around all the fields as configured in the
    #   Ubiquo::Config.context(:ubiquo_form_builder).get(:default_tag_options)
    #
    #   So all methods mentioned have the following options added, and the proxy
    #   (UbiquoFormBuilder instance) processes them accordingly.
    #
    #   Options for the form field helper methods:
    #   +:translatable+: used to say that the field is translatable. It adds the required
    #     markup to use it. It accepts boolean or a string that will be rendered on the field
    #   +:description+: expects a string that will be shown after the field to
    #     describe the meaning of the field.
    #   +:help+: expects a string that will be shown as a visual tip when user clicks on
    #   a question mark icon.
    #   +label+: the text that the label will show or the full options passed
    #     to the #label method.
    #   +label_at_bottom+: positions the label after the input. Sometimes used by checkboxes.
    #   +label_as_legend+: renders the label as legend of the wrapping fieldset
    #   +group+: accepts group configurations. See #group method doc.
    #

    class UbiquoFormBuilder < ActionView::Helpers::FormBuilder

      cattr_accessor :default_tag_options, :groups_configuration
      attr_accessor :group_chain, :builder_options, :enabled

      helpers = field_helpers + %w{date_select datetime_select time_select} +
        %w{collection_select select country_select time_zone_select}

      # TODO: integrate relation_selector to this. It now decides the format
      # depending on the type of selector is used (checkbox or select tags)
      ubiquo_helpers = %w{}

      # Dont decorate these
      helpers -= %w{hidden_field label fields_for}

      Ubiquo::Config.context(:ubiquo_form_builder) do |context|
        self.default_tag_options = context.get(:default_tag_options)
        self.groups_configuration = context.get(:groups_configuration)
      end

      # Overwrites the method given by +name+ with Module#define_method to add
      # a label before the tag and group the result in a div.
      # +tag_options+ allows to set the default tag options for +name+.
      #
      # This is usually defined in initializers but can be overwritten here.
      #
      # The methods are documented on the class description
      #
      def self.initialize_method( name, tag_options = nil )
        default_tag_options[name.to_sym] = tag_options if tag_options
        define_method(name) do |field, *args|
          return super unless self.enabled
          options_for_tag = (default_tag_options[name.to_sym] || {}).clone
          options_position = (options_for_tag && options_for_tag.delete(:options_position)) || -1 # last by default
          options = args[options_position].is_a?(Hash) ? args[options_position] : {}
          # Accept a closure
          options_for_tag = options_for_tag.call(binding, field, options ) if options_for_tag.respond_to? :call
          options = options.reverse_merge( options_for_tag )

          # not (delete || {}) because we support :group => false
          group_options = ( options.has_key?(:group) ? options.delete( :group ) : {} )
          group_options = group_options.dup if group_options.is_a? Hash

          translatable = options.delete(:translatable)
          description = options.delete(:description)
          help = options.delete(:help)

          label_name = options.delete(:label) || @object.class.human_attribute_name(field)
          label = ""
          if options[:label_as_legend]
            # We'll render a legend in spite of a label.
            group_options[:label] = label_name
          else
            label = label(field, *label_name )
          end
          label_at_bottom = options.delete(:label_at_bottom)

          unless args[options_position].is_a?(Hash)
            # We cannot set a negative position if it does not exist
            if options_position == -1
              args << options
            else
              args[options_position] = options
            end
          end
          super_result = super( field, *args )

          pre = ""
          post = ""
          if( label_at_bottom )
            post += label
          else
            pre += label
          end

          post += group(:type => :help) do
            help
          end if help
          post += group(:type => :translatable) do
            ( translatable === true ? @template.t("ubiquo.translatable_field") : translatable )
          end if translatable
          post += group(:type => :description) do
            description
          end if description

          if group_options
            group(group_options) do
              pre + super_result + post
            end
          else
            pre + super_result + post
          end
        end
      end

      (helpers + ubiquo_helpers).each do |name|
        initialize_method( name )
      end

      def initialize(*args)
        super(*args)
        Ubiquo::Config.context(:ubiquo_form_builder) do |ctx|
          self.builder_options = {
            :unfold_tabs => ctx.get(:unfold_tabs),
            :default_group_type => ctx.get(:default_group_type),
            }
          if self.builder_options[:unfold_tabs]
            groups_configuration[:tabbed] = groups_configuration[:tabbed_unfolded]
          end
        end
        self.group_chain = []
        self.enabled = true #Enabled by default
      end

      # Wrapper of fields or tags
      #
      # Options are:
      #   +:type+: the type name of group to render. The default group name is
      #     read from Ubiquo::Config.context(:ubiquo_form_builder).get(:default_group_type)
      #     We get default configuration based on this type. Some of the available
      #     types are :div, :fieldset and :tabbed. To see all of them look at the
      #     ubiquo_core/rails/init.rb in :groups_configuration or get there in runtime.
      #   +:callbacks+: allow to add content before and after with the string
      #     generated by a proc. A hash with :before and :after keys.
      #   +:legend+: to give the text for the legend field in case of a fieldset
      #   +:partial+: allow to render custom partial to represent the info
      #   +:before+: string to append inside the wrapper before all the field content.
      #   +:after+: string to append inside the wrapper after the content.
      #
      # Example of tabbed form:
      #
      #     <% form.group(:type=>:tabbed) do %>
      #       <% form.tab("Personal data") do %>
      #         <%= f.text_field :first_name %>
      #         <%= f.text_field :last_name %>
      #       <% end %>
      #       <% form.tab("Working at") do %>
      #         <%= f.text_field :company_name %>
      #         <%= f.text_field :title %>
      #       <% end %>
      #     <% end %>
      #
      def group(options = {}, &block)
        return yield unless self.enabled

        type = options.delete(:type) || self.builder_options[:default_group_type]
        options = options.reverse_merge( groups_configuration[type] || {})

        if options[:partial]
          result = @template.render :partial => options[:partial],
            :locals => options.merge(:content => @template.capture(&block).to_s)
        else
          options[:class] = [
              options[:class],
              options.delete(:append_class)
          ].delete_if(&:blank?).compact.join(" ")

          block_group = BlockGroup.new( self, options.merge(:type => type) )
          self.group_chain << block_group
          tag = options.delete(:content_tag) # Delete it before sending to content_tag
          callbacks = options.delete(:callbacks) || {}
          result = @template.content_tag(tag, options) do
            out = ""
            out += callbacks[:before].call( binding, options ).to_s if callbacks[:before].respond_to?(:call)
            out += options.delete(:before).to_s
            out += @template.capture(block_group, &block ).to_s
            out += options.delete(:after).to_s
            out += callbacks[:after].call( binding, options ).to_s if callbacks[:after].respond_to?(:call)
            out
          end
          self.group_chain.pop
        end
        # Any method here that accepts a block must check before concat
        manage_result( result, block )
      end

      # Block to disable UbiquoFormbBuilder "magic" inside it.
      def custom_block(&block)
        last_status = self.enabled
        self.enabled = false
        begin
          manage_result( @template.capture( &block ).to_s, block )
        ensure
          self.enabled = last_status
        end
      end

      # Custom group for the submit buttons.
      def submit_group( options = {}, &block )
        options[:type] = :submit_group
        group( options, &block )
      end

      # Button to submit the new form
      def create_button( text = nil, options = {} )
        options = options.reverse_merge( default_tag_options[:create_button] )
        text = text || @template.t(options.delete(:i18n_label_key))
        submit text, options
      end

      # Button to submit on the edit form
      def update_button( text = nil, options = {} )
        options = options.reverse_merge( default_tag_options[:update_button] )
        text = text || @template.t(options.delete(:i18n_label_key))
        submit text, options
      end

      # Creates a tab on the current block.
      # It raises an exception unless last group is a group(:type=> :tabbed)
      def tab( name, options= {}, &block)
        if self.group_chain.last && self.group_chain.last.options[:type].to_s.include?("tabbed")
          self.group_chain.last.add( name, options, &block)
        else
          raise "Cannot call UbiquoFormBuider#tab without being in a tabbed group"
        end
      end

      # Shows the back button for a form. Going back to controler index page.
      #
      # +text+ is the text shown in the button.
      #
      # +options+ available:
      #   +:url+ to go back. It's controller index by default
      #   +:i18n_label_key+ key for the translation unless text is not null
      #   +:js_function+ is the function passed to button_to_function.
      #     "document.location.href=..." by default
      #
      def back_button( text = nil, options = {} )
        # FIXME: this url generation does not support nested controllers
        url = options.delete(:url) ||
          @template.send( "ubiquo_" + (@object.class.to_s.pluralize.underscore) + "_path" )
        options = options.reverse_merge(default_tag_options[:back_button])

        text = text || @template.t(options[:i18n_label_key])
        options.delete(:i18n_label_key)
        js_function = options[:js_function] || "document.location.href='#{url}'"

        # @template.button_to_function text, js_function, options
        @template.link_to text, url, :class => 'back'
      end

      # It's a group of blocks. Used by tab construction
      class BlockGroup
        attr_accessor :form_builder, :options

        def initialize(ubiquo_form_builder, options = {})
          self.form_builder = ubiquo_form_builder
          self.options = options
        end

        # Recieves a block of form that will be grouped and named by name
        #   +name+ The name of the tab or fieldset
        #   +group_options+ are options passed to the wrapper of the block.
        def add( name, group_options = {}, &block )
          form_builder.group(group_options.reverse_merge({:type => :tab,:legend => name}), &block)
        end
      end

      protected
      # Any method here that accepts a block must check in case it has been called
      # from an erb.
      #
      # In that case we must concat te result to the template, otherways the result
      # will not appear on the response.
      #
      # Notice that block must not have to have an ampersand
      def manage_result result, block
        @template.concat( result ) if @template.send(:block_called_from_erb?, block )
        result
      end

    end
  end

end
