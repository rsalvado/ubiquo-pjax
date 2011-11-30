module Ubiquo
  module Filters
    class DateFilter < BaseFilter

      def configure(options = {})
        options[:field] = add_filter_prefix_when_needed(options[:field]) if options[:field]
        @options = {
          :field       => [:filter_publish_start, :filter_publish_end],
          :caption     => @model.human_attribute_name("published_at"),
          :box_id      => Array(options[:field]).first.to_s.dasherize.split('-').first(2).join('-')
        }.merge(options)
      end

      def render
        date_start_field, date_end_field = @options[:field].map(&:to_sym)
        year_range = ((@options[:year_start] || 2000)..(@options[:year_end] || Time.now.year))
        calendar_options = {:popup => true, :year_range => year_range}
        lateral_filter(@options) do |keepable_params|
          @context.calendar_includes + \
          @context.content_tag(:div, :id => 'date_filter_content') do
            @context.form_tag(@options[:url_for_options], :method => :get, :id => "frm_calendar") do
              hidden_fields(keepable_params) + \
              @context.content_tag(:div, :class => 'form-item') do
                @context.content_tag(:label, :for => "filter_" + date_start_field.to_s) { I18n.t('ubiquo.base.from') } + \
                @context.calendar_date_select_tag(date_start_field, @context.params[date_start_field],
                                                  calendar_options.merge(:id => "filter_" + date_start_field.to_s))
              end + \
              @context.content_tag(:div, :class => 'form-item') do
                @context.content_tag(:label, :for => "filter_" + date_end_field.to_s) { I18n.t('ubiquo.base.to') } + \
                @context.calendar_date_select_tag(date_end_field, @context.params[date_end_field],
                                                  calendar_options.merge(:id => "filter_" + date_end_field.to_s))
              end + \
              @context.content_tag(:div, :class => 'form-item-submit') { @context.submit_tag(I18n.t('ubiquo.search'), :class => 'bt-filter-submit') }
            end
          end
        end
      end

      def message
        date_start_field, date_end_field = @options[:field].map(&:to_sym)
        date_start = param_value(date_start_field)
        date_end = param_value(date_end_field)
        return unless date_start or date_end
        info = if date_start and date_end
                 I18n.t('ubiquo.filters.filter_between', :date_start => date_start, :date_end => date_end)
               elsif date_start
                 I18n.t('ubiquo.filters.filter_from', :date_start => date_start)
               elsif date_end
                 I18n.t('ubiquo.filters.filter_until', :date_end => date_end)
               end
        info2 = @options[:caption] + " " + info if @options[:caption]
        [info2, [date_start_field, date_end_field]]
      end

      private

      def add_filter_prefix_when_needed(fields)
        fields.map { |f| add_filter_prefix(f) } if fields.kind_of?(Array)
      end

      def param_value(field)
        @context.params[field] if !@context.params[field].blank?
      end

    end
  end
end
