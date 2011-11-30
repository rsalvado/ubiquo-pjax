module UbiquoCategories
  module Extensions
    module Helpers

      # Adds a tab for the category set section
      def category_sets_tab(navtab)
        navtab.add_tab do |tab|
          tab.text = I18n.t("ubiquo.categories.categories")
          tab.title = I18n.t("ubiquo.categories.categories")
          tab.highlights_on "ubiquo/category_sets"
          tab.highlights_on "ubiquo/categories"
          tab.link = ubiquo_category_sets_path
        end if ubiquo_config_call(:categories_permit, {:context => :ubiquo_categories})
      end

      protected

      # Prepares a collection
      def categories_for_select key
        uhook_categories_for_set category_set(key)
      end

      def category_set(key)
        key = key.to_s.pluralize
        CategorySet.find_by_key(key) ||
        CategorySet.find_by_key(key.singularize) ||
        raise(SetNotFoundError.new(key))
      end

    end
  end
end
