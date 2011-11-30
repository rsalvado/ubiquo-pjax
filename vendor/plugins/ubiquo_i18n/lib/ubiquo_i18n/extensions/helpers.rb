module UbiquoI18n
  module Extensions
    
    # This module provides some builtin helpers to be used in views
    module Helpers
      
      # Returns a selector of the currently active locales, ordered 
      # alphabetically, with the current locale selected.
      #
      # Options can contain the following options:
      #   :keep_page => unless true, the page parameter is removed in the
      #                 destination url, to prevent wrong page number in index pages

      def locale_selector(options = {})
        redirect_params = params.dup
        redirect_params.delete(:page) unless options[:keep_page]
        if Locale.active.size > 1
          form_tag(url_for(redirect_params), :method => :get) +
            html_unescape(select_tag("locale",
                                     options_for_locale_selector,
                                     :id => "locale_selector")) +
            "</form>"
        end
      end
      
      # For a given model, show their translations with a link to them
      def show_translations(model, options = {})
        return if model.in_locale?(:any)
        render :partial => "shared/ubiquo/model_translations", 
               :locals => {:model => model, :options => options}
      end
      
      # Adds a tab to display the locales section inside superadmin area
      def superadmin_locales_tab(navtab)
        navtab.add_tab do |tab|
          tab.text = I18n.t("ubiquo.i18n.translations")
          tab.title = I18n.t("ubiquo.i18n.translations_title")
          tab.highlights_on({:controller => "ubiquo/locales"})
          tab.link = ubiquo_locales_path
        end if ubiquo_config_call(:assets_permit, {:context => :ubiquo_media})
      end
      
      def options_for_locale_selector
        options_from_collection_for_select(Locale.active.ordered_alphabetically,
                                           :iso_code, 
                                           :humanized_name,
                                           current_locale)
      end
    end
  end
end
