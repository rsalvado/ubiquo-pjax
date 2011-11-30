module Ubiquo
  module Filters
    class TextFilter < BaseFilter

      def configure(options={})
        options[:field] = add_filter_prefix(options[:field]) if options[:field]
        defaults = {
          :field       => :filter_text,
          :caption     => I18n.t('ubiquo.filters.text'),
        }
        @options = defaults.merge(options)
      end

      def render
        lateral_filter(@options) do |keepable_params|
          @context.form_tag(@options[:url_for_options], :method => :get) do
            hidden_fields(keepable_params) + \
            @context.content_tag(:div, :class => 'form-item-submit') do
              @context.text_field_tag(@options[:field], @context.params[@options[:field]]) + "\n" + \
              @context.submit_tag(I18n.t('ubiquo.search'), :class => 'bt-filter-submit')
            end
          end
        end
      end

      def message
        field = @options[:field].to_s
        string = !@context.params[field].blank? && @context.params[field]
        return unless string
        info = @options[:caption].blank? ?
        I18n.t('ubiquo.filters.filter_text', :string => string) :
          "#{@options[:caption]} '#{string}'"
        [info, [field]]
      end

    end
  end
end
