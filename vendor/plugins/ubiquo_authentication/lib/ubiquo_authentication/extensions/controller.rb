module UbiquoAuthentication
  module Extensions
    module Controller
      #Adds a befor filter to the controller that includes that module
      #calling to the method
      #UbiquoAuthentication::Extensions::Controller.set_ubiquo_locale. 
      def self.included(klass)
        klass.before_filter :set_ubiquo_locale
      end
      
      #sets the rails I18n locale that the user has selected in their
      #user profile.If none selected (or 'use default locale' option)
      #this will set the Ubiquo.default_locale(see ubiquo_core doc)
      #value as the selected locale.
      def set_ubiquo_locale
        return true unless logged_in?
        user_locale = current_ubiquo_user.locale
        user_locale = nil if user_locale.blank?
        I18n.locale = user_locale || Ubiquo.default_locale
        true
      end
    end
  end
end
