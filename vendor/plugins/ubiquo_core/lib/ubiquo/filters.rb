# See ubiquo_core guide for more information about filters.
# For edge: http://guides.ubiquo.me/edge/ubiquo_core.html

module Ubiquo
  module Filters

    class UbiquoFilterError < StandardError; end
    class UnknownFilter < UbiquoFilterError; end
    class MissingFilterSetDefinition < UbiquoFilterError; end

    class FilterSetBuilder

      attr_reader :filters

      def initialize(model, context)
        @model = model.constantize
        @context = context
        @filters = []
      end

      def method_missing(method, *args, &block)
        filter = get_filter_class(method).new(@model, @context)
        filter.configure(*args,&block)
        @filters << filter
      end

      # Renders all filters of the set, in order, as a string
      def render
        @filters.map { |f| f.render }.join("\n")
      end

      # Renders the human message, associated with active filters of
      # the set, as a string
      def message
        info_messages = @filters.inject([]) do |result, filter|
          result << filter.message
        end
        build_filter_info(info_messages)
      end

      # TODO: Make private in ubiquo 0.9.0. Public for now to
      # maintain the deprecated interface.
      def build_filter_info(info_messages)
        fields, string = process_filter_info(info_messages)
        return unless fields
        info = @context.content_tag(:strong, string)
        # Remove keys from applied filters and other unnecessary keys (commit, page, ...)
        remove_fields = fields + [:commit, :page]
        new_params = @context.params.clone
        remove_fields.each { |field| new_params[field] = nil }
        link_text = I18n.t('ubiquo.filters.remove_all_filters', :count => fields.size)
        message = [ I18n.t('ubiquo.filters.filtered_by', :field => info), @context.link_to(link_text, new_params, :class => 'bt-remove-filters')]
        @context.content_tag(:p, message.join(" "), :class => 'search_info')
      end

      private

      # Return the pretty filter info string
      #
      # info_and_fields: array of [info_string, fields_for_that_filter]
      def process_filter_info(info_and_fields)
        info_and_fields.compact!
        return if info_and_fields.empty?
        # unzip pairs of [text_info, fields_array]
        strings, fields0 = info_and_fields[0].zip(*info_and_fields[1..-1])
        fields = fields0.flatten.uniq
        [fields, string_enumeration(strings)]
      end

      # From an array of strings, return a human-language enumeration
      def string_enumeration(strings)
        strings.reject(&:empty?).to_sentence()
      end

      # Given a filter_for method name returns the appropiate filter class
      def get_filter_class(filter_name)
        camel_cased_word = "Ubiquo::Filters::#{filter_name.to_s.classify}Filter"
        camel_cased_word.split('::').inject(Object) do |constant, name|
          constant = constant.const_get(name)
        end
      end

    end

    # Defines a filter set. For example:
    #  # app/helpers/ubiquo/articles_helper.rb
    #  module Ubiquo::ArticlesHelper
    #    def article_filters
    #       filters_for 'Article' do |f|
    #         f.text
    #         f.locale
    #         f.date
    #         f.select :name, @collection
    #         f.boolean :status
    #       end
    #    end
    #  end
    def filters_for(model,&block)
      raise ArgumentError, "Missing block" unless block
      filter_set = FilterSetBuilder.new(model, self)
      yield filter_set
      @filter_set = filter_set
    end

    # Render  a filter set
    def show_filters
      initialize_filter_set_if_needed
      @filter_set.render
    end

    # Render a filter set human message
    def show_filter_info
      initialize_filter_set_if_needed
      @filter_set.message
    end

    # TODO: The following public methods should be deprecated in the
    # 0.9.0 release

    # Render a lateral filter
    #
    # filter_name (symbol): currently implemented: :date_filter, :string_filter, :select_filter
    # url_for_options: route used by the form (string or hash)
    # options_for_filter: options for a filter (see each *_filter_info helpers for details)
    def render_filter(filter_name, url_for_options, options = {})
      deprecation_message
      options[:url_for_options] = url_for_options
      filter_name = :boolean if options[:boolean]
      filter = select_filter(filter_name, options)
      filter.render
    end

    # Return the informative string about a filter process
    #
    # filter_name (symbol). Currently implemented: :date_filter, :string_filter, :select_filter
    # params: current 'params' controller object (hash)
    # options_for_filter: specific options needed to build the filter string (hash)
    #
    # Return array [info_string, fields_used_by_this_filter]
    def filter_info(filter_name, params, options = {})
      deprecation_message
      filter = select_filter(filter_name, options)
      filter.message
    end

    # Return the pretty filter info string
    #
    # info_and_fields: array of [info_string, fields_for_that_filter]
    def build_filter_info(*info_and_fields)
      deprecation_message
      model = self.controller_name.classify
      fs = FilterSetBuilder.new(model, self)
      fs.build_filter_info(info_and_fields)
    end

    private

    # Initializes filter set definition if it isn't already.
    # We need to do this because sometimes we need to render the
    # messages before filters are defined.
    # So if we don't have a filter set we try to run the helper
    # method we expect that will define them.
    #
    # Ex: For the articles_controller we will execute the
    # article_filters method to load the filter set definition.
    #
    # Thanks to this trick we avoid to define filters two times one
    # for messages and one for render.
    def initialize_filter_set_if_needed
      helper = "#{@controller.controller_name.singularize}_filters"
      send(helper) unless @filter_set
    end

    # Transitional method to maintain compatibility with the old
    # filter interface.
    # TODO: To be removed from the 0.9.0 release
    def select_filter(name, options)
      model = self.controller_name.classify.constantize
      field = options[:field]
      case name
      when :single_date
        (SingleDateFilter.new(model, self)).tap { |f| f.configure(options) }
      when :date
        (DateFilter.new(model, self)).tap { |f| f.configure(options) }
      when :string
        (TextFilter.new(model, self)).tap { |f| f.configure(options) }
      when :select
        (SelectFilter.new(model, self)).tap { |f| f.configure(field, options[:collection], options) }
      when :links
        (LinkFilter.new(model, self)).tap { |f| f.configure(field, options[:collection], options) }
      when :links_or_select
        (LinksOrSelectFilter.new(model, self)).tap { |f| f.configure(field, options[:collection], options) }
      when :boolean
        (BooleanFilter.new(model, self)).tap { |f| f.configure(field, options)}
      end
    end

    # Transitional method to maintain compatibility with the old
    # filter interface.
    # TODO: To be removed from the 0.9.0 release
    def deprecation_message
      caller_method_name = caller.first.scan /`([a-z_]+)'$/
      msg = "#{caller_method_name} will be removed in 0.9.0. See http://guides.ubiquo.me/edge/ubiquo_core.html for more information."
      ActiveSupport::Deprecation.warn(msg, caller(2))
    end

  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, Ubiquo::Filters)
