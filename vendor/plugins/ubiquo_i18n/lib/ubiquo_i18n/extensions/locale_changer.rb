module UbiquoI18n
  module Extensions
    module LocaleChanger
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :helper_method, :current_locale
        klass.send :before_filter, :current_locale
      end
      
      module InstanceMethods
        # Returns the current locale, and sets it in the session if it wasn't there
        def current_locale
          if @current_locale.blank?
            @current_locale ||= params[:locale] || session[:locale] ||ubiquo_config_call(:last_user_locale, {:context => :ubiquo_i18n})  || Locale.default
            Locale.current = session[:locale] = @current_locale
            ubiquo_config_call(:set_last_user_locale, {:context => :ubiquo_i18n, :locale => @current_locale})
          end
          @current_locale
        end
      end
    end
  end
end
