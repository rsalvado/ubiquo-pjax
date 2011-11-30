module UbiquoI18n
  module Extensions
    module TestCase
      #This method allows functional test to simulate a ubiquo_user login by setting session value
      #
      #If the attribute is a Symbol, the user is getted from fixture helper ubiquo_users(fixture_name).
      #For example, if :one is passed, a fixture named with 'one:' will be used
      #
      #If the attribute is a UbiquoUser, that user is used.
      #
      #If the attribute is nil (or none setted) the 'admin' named fixture will be used
      #
      #If the attribute is a number, this number will be used as a ubiquo_user_id, but don't validates to be a valid id.
      def set_session_locale(locale = nil)
        if @request
          @request.session[:locale] = locale || Locale.default
        end
      end
      
    end
  end
end
