module Ubiquo
  module Filters
    class BooleanFilter < LinkFilter

      def configure(field, options = {})
        defaults = {
          :field         => "filter_#{field}",
          :caption       => @model.human_attribute_name(field),
          :caption_true  => I18n.t('ubiquo.filters.boolean_true'),
          :caption_false => I18n.t('ubiquo.filters.boolean_false'),
        }
        @options = defaults.merge(options)
        collection = [
          OpenStruct.new(:option_id => 0, :name => @options[:caption_false]),
          OpenStruct.new(:option_id => 1, :name => @options[:caption_true]),
        ]
        boolean_options = {
          :id_field => :option_id,
          :name_field => :name,
          :collection => collection
        }
        @options.update(boolean_options)
      end

    end
  end
end
