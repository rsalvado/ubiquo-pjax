module Ubiquo
  module Filters
    class SingleDateFilter < BaseFilter

      def configure(options = {})
        options[:field] = add_filter_prefix_when_needed(options[:field]) if options[:field]
        @options = {
          :field => :filter_publish_end,
          :caption => @model.human_attribute_name("published_at")
        }.merge(options)
      end

      def render
        filter_field = @options[:field]
        date_field = @options[:field].to_sym
        year_range = ((@options[:year_start] || 2000)..(@options[:year_end] || Time.now.year))
        calendar_options = {:popup => true, :year_range => year_range}
        lateral_filter(@options) do |keepable_params|
          @context.calendar_includes + \
          @context.content_tag(:div, :id => 'date_filter_content') do
            @context.form_tag(@options[:url_for_options], :method => :get, :id => "frm_calendar") do
              hidden_fields(keepable_params) + \
              @context.content_tag(:div, :class => 'form-item') do
                @context.content_tag(:label, :for => "filter_" + date_field.to_s) { I18n.t('ubiquo.base.to') } + \
                @context.calendar_date_select_tag(date_field, @context.params[date_field],
                                                  calendar_options.merge(:id => "filter_" + date_field.to_s))
              end + \
              @context.content_tag(:div, :class => 'form-item-submit') { @context.submit_tag(I18n.t('ubiquo.search'), :class => 'bt-filter-submit') }
            end
          end
        end
      end

      def message
        date_field = @options[:field].to_sym
        date = @context.params[date_field]

        return unless date
        info = I18n.t('ubiquo.filters.filter_until', :date_end => date)

        info = @options[:caption] + " " + info if @options[:caption]
        [info, [date_field]]
      end

    end
  end
end
