module Ubiquo
  module Helpers
    module CoreUbiquoHelpers

      class AssociationNotFound < StandardError; end

      # Adds the default stylesheet tags needed for ubiquo
      # options:
      #   color: by default is red, but you can replace it calling another color
      #          css file
      #   rest of options: this helper doesn't user more options, the rest are
      #                    send to stylesheet_link_tag generic helper
      def ubiquo_stylesheet_link_tag(*sources)
        stylesheets_dir = ActionView::Helpers::AssetTagHelper::STYLESHEETS_DIR + '/ubiquo'
        options = sources.extract_options!.stringify_keys
        color = options.delete("color") || :red
        default_sources = []
        if sources.include?(:defaults)
          default_sources += [:ubiquo, :ubiquo_application, :lightwindow, :ubiquo_lightwindow, :listings, color]
          default_sources += collect_asset_files("#{stylesheets_dir}", "plugins/*.css")
          default_sources += [:ipad] if defined?( request ) && request.user_agent.match(/Apple.*Mobile/)
        end
        ubiquo_sources = (sources + default_sources).collect do |source|
          next if source == :defaults
          "ubiquo/#{source}"
        end.compact
        output = stylesheet_link_tag(ubiquo_sources, options)
        if sources.include?(:defaults)
          output += <<-eos
            <!--[if IE]>
              #{stylesheet_link_tag 'ubiquo/ubiquo_ie'}
            <![endif]-->
            <!--[if lte IE 6]>
              #{stylesheet_link_tag 'ubiquo/ubiquo_ie6'}
            <![endif]-->
          eos
        end
        output
      end

      def ubiquo_javascript_include_tag(*sources)
        javascripts_dir = ActionView::Helpers::AssetTagHelper::JAVASCRIPTS_DIR + '/ubiquo'
        options = sources.extract_options!.stringify_keys
        default_sources = []
        if sources.include?(:defaults)
          default_sources += [:ubiquo, :lightwindow, :lightwindow_ubiquo]
          default_sources += collect_asset_files("#{javascripts_dir}", "plugins/*.js")
        end
        ubiquo_sources = (sources + default_sources).collect do |source|
          next if source == :defaults
          "ubiquo/#{source}"
        end.compact
        javascript_include_tag(ubiquo_sources, options)
      end

      # surrounds the block between the specified box.
      def box(name, options={}, &block)
        options.merge!(:body=>capture(&block))
        concat(render(:partial => "shared/ubiquo/boxes/#{name}", :locals => options), block.binding)
      end

      # This is a wrapper for image_tag for images inside the "ubiquo" directory
      # This folder can be changed using the :ubiquo_path configuration option
      def ubiquo_image_tag(source, options={})
        image_tag(ubiquo_image_path(source), options)
      end

      # Returns the path for an ubiquo image
      def ubiquo_image_path(name)
        "#{Ubiquo::Config.get(:ubiquo_path)}/#{name}"
      end

      # Returns a "tick" or "cross" image, useful to display boolean values
      def ubiquo_boolean_image(value)
        content_tag(:span, value, :class => "state_#{value}")
      end

      # Returns a properly marked up ubiquo sidebar box.
      # Used to display sidebar items like filters, help boxes, etc.
      def ubiquo_sidebar_box(title, options, &block)
        css_class = "sidebar_box #{options[:class]}".strip
        extra_header = options[:extra_header] || ''
        result = content_tag(:div, :class => css_class, :id => options[:id]) do
          content_tag(:div, :class => "header") do
            content_tag(:h3, title) + extra_header
          end + \
          content_tag(:div, capture(&block), :class => "content")
        end
        block_called_from_erb?(block) ? concat(result) : result
      end

      # Return true if string_date is a valid date representation with a
      # given format (the so-called italian format by default: %d/%m/%Y)
      def is_valid_date?(string_date, format="%d/%m/%Y")
        begin
          time = Date.strptime(string_date, format)
        rescue ArgumentError
          return false
        end
        true
      end

      # Include calendar_date_select javascript and stylesheets
      # with a default theme, basedir and locale
      def calendar_includes(options = {})
        iso639_locale = options[:locale] || I18n.locale.to_s
        CalendarDateSelect.format = options[:format] || :italian
        calendar_date_select_includes "ubiquo", :locale => iso639_locale
      end

      # Renders a message in a help block in the sidebar
      def help_block_sidebar(message)
        ubiquo_sidebar_box(t("ubiquo.help"), :class => "help-box") do
          "<p>#{message}</p>"
        end
      end

      # Renders a preview
      # A preview is usually used to show the values of an instance somewhere,
      # in an unobtrusive way
      # The instance to preview is taken from params[:preview_id]
      def show_preview(model_class, options = {}, &block)
        return unless params[:preview_id]
        previewed = model_class.find(params[:preview_id], options)
        return unless previewed
        locals = {:body=>capture(previewed, &block)}
        concat(render(:partial => "shared/ubiquo/preview_box", :locals => locals))
      end

      # converts symbol to ubiquo standard table head with order_by and sort_order strings
      def ubiquo_table_headerfy(column, klass = nil)
        name = klass.nil? ? params[:controller].split("/").last.tableize : klass

        case column
          when Symbol
            link = params.clone
            if link[:order_by] == "#{name.to_s.pluralize}.#{column.to_s}"
              link[:sort_order] = link[:sort_order] == "asc" ? "desc" : "asc"
            else
              link[:order_by] = "#{name.pluralize}.#{column.to_s}"
              link[:sort_order] = "asc"
            end
            #name.classify.human_attribute_name(column.to_s.humanize)
            #t("#{name.classify}|#{column.to_s.humanize}").humanize

            column_segments = column.to_s.split('.') # Example column: :"author.name"
            column_header = if column_segments.size > 1
              begin
                # Here we are dealing with relation columns
                assoc_model = column_segments.first.classify.constantize
                column_name = assoc_model.human_attribute_name(column_segments.last)
                assoc_model.human_name.downcase
              rescue NameError
                # Here we are dealing with relation columns using categories
                category = CategorySet.find_by_key(column_segments.first)
                msg = "Couldn't find #{column_segments.first} association for #{column_name} column."
                raise AssociationNotFound, msg unless category
                category.name
              end
            else
              name.classify.constantize.human_attribute_name(column.to_s)
            end

            link_to content_tag(:span, column_header),
                    link,
                    { :class => (params[:order_by] == "#{name.pluralize}.#{column.to_s}" ?
                                (params[:sort_order] == "asc" ? "order_desc" : "order_asc") : "order" )}
          when String
            column.humanize
        end
      end

      # Method to activate the usage of the ubiquo form builder
      def ubiquo_form_for(record_or_name_or_array, *args, &proc)
        opts = (args.last || {})
        opts[:builder] = UbiquoFormBuilder
        args << opts if !args.last
        form_for(record_or_name_or_array, *args, &proc)
      end
    end
  end
end
