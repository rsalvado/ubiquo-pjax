module UbiquoCategories
  module Filters
    class CategoryFilter < Ubiquo::Filters::LinksOrSelectFilter

      def configure(set, options = {})
        defaults = {
          :collection => categories_for_select(set),
          :caption => options[:caption] || I18n.t("ubiquo.category_sets.#{set}"),
          :field => "filter_#{set.to_s}",
          :id_field => :name,
          :name_field => :name
        }
        @options = defaults.merge(options)
      end

      private

      # Prepares a collection
      def categories_for_select key
        @context.uhook_categories_for_set category_set(key)
      end

      def category_set(key)
        key = key.to_s.pluralize
        CategorySet.find_by_key(key) || raise(SetNotFoundError.new(key))
      end

    end
  end
end
