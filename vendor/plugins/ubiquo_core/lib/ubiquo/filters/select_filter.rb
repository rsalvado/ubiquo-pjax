# -*- coding: utf-8 -*-
module Ubiquo
  module Filters
    class SelectFilter < BaseFilter

      def configure(field, collection, options={})
        options[:field] = add_filter_prefix(field)
        defaults = {
          :collection  => collection,
          :id_field    => :id,
          :name_field  => default_name_field(collection),
          :caption     => @model.human_attribute_name(field),
          :all_caption => @model.human_attribute_name(field),
        }
        @options = defaults.merge(options)
      end

      def render
        filter_field = @options[:field]
        header_option = @options[:all_caption] ? "<option value=''>" + @options[:all_caption] + "</option>" : ""
        field_value = (@context.params[filter_field] =~ /^\d+/)? @context.params[filter_field].to_i : @context.params[filter_field]
        field_value = @context.params[filter_field].map(&:to_i) if @context.params[filter_field].is_a?(Array)
        lateral_filter(@options) do |keepable_params|
          @context.content_tag(:div, :id => 'select_filter_content') do
            @context.form_tag(@options[:url_for_options], :method => :get) do
              @context.content_tag(:div, :class => 'form-item-submit') do
                hidden_fields(keepable_params) + \
                @context.select_tag(filter_field,
                           header_option + @context.options_from_collection_for_select(@options[:collection],
                                                                              @options[:id_field],
                                                                              @options[:name_field],
                                                                              (@context.params[filter_field].blank? ? @options[:default_selected] : field_value)),
                           {:id => nil}.merge(@options[:html_options] || {})) + \
                @context.submit_tag(I18n.t("ubiquo.search"), :class => "select_filter bt-filter-submit")
              end
            end
          end
        end
      end

      def message
        field_key = @options[:field] || raise("options: missing 'field' key")
        field = !@context.params[field_key].blank? && @context.params[field_key]
        return unless field
        name = if @options[:boolean]
                 caption_true = @options[:caption_true] || raise("options: missing 'caption_true' key")
                 caption_false = @options[:caption_false] || raise("options: missing 'caption_false' key")
                 (@context.params[field_key] == "1") ? caption_true : caption_false
               else
                 if @options[:model]
                   id_field = @options[:id_field] || raise("options: missing 'id_field' key")
                   model = @options[:model].to_s.classify.constantize
                   record = model.find(:first, :conditions => {id_field => @context.params[field_key]})
                   return unless record
                   name_field = @options[:name_field] || raise("options: missing 'name_field' key")
                   record.send(name_field)
                 elsif @options[:collection]
                   value = @options[:collection].find do |value|
              value.send(@options[:id_field]).to_s == @context.params[field_key]
            end.send(@options[:name_field]) rescue @context.params[field_key]
                 else
                   prefix = @options[:translate_prefix]
                   prefix ? @context.I18n.t("#{prefix}.filters.#{@context.params[field_key]}") : @context.params[field_key]
                 end
               end
        info = "#{@options[:caption]} '#{name}'"
        [info, [field_key]]
      end

      private

      def default_name_field(collection)
        return unless collection.is_a? Array
        element = collection.first
        if element.respond_to?(:name)
          :name
        elsif element.respond_to?(:title)
          :title
        end
      end

    end

  end
end
