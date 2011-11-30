module Ubiquo
  module Filters
    class BaseFilter

      def initialize(model,context)
        @model, @context = model, context
      end

      def lateral_filter(options = {}, &block)
        return if options[:collection] && options[:collection].empty?
        box_id = "box-" + (options[:box_id] || options[:field].to_s.dasherize)
        fields = [options[:field]].flatten
        title  = I18n.t("ubiquo.filter", :thing => options[:caption])
        @context.ubiquo_sidebar_box(title, :class => 'filters-box', :id => box_id, :extra_header => disable_link(fields)) do
          yield(extract_keepable_params(fields))
        end
      end

      def disable_link(fields)
        if fields.map { |f| @context.params[f].blank? }.include?(false)
          without_filters = @context.params.dup
          fields.each { |f| without_filters[f] = nil}
          without_filters.delete(:page)
          without_filters.delete(:commit)
          without_filters.delete(:_pjax)
          @context.link_to(I18n.t('ubiquo.filters.remove_filter'), without_filters, :class => 'bot_filters')
        else
          ""
        end
      end

      def extract_keepable_params(fields)
        @context.params.reject do |key, values|
          filter_fields = fields.flatten.map(&:to_s)
          toremove = %w{commit controller action page _pjax} + filter_fields
          toremove.include?(key)
        end.to_hash
      end

      def hidden_fields(hash)
        hash.map do |field, value|
          if value.is_a? Array
            value.map {|val| hidden_field_tag field+"[]", val}.flatten
          else
            @context.hidden_field_tag field, value, :id => nil
          end
        end.join("\n")
      end

      def add_filter_prefix(field)
       if field.to_s.match(/^filter_/)
         field
        else
         "filter_#{field}".to_sym
        end
      end

    end
  end
end
