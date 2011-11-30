module UbiquoAuthentication
  module AuthenticatedSystem
    
    # Returns true or false if the ubiquo_user is logged in.
    def logged_in?
      current_ubiquo_user != :false
    end

    # Accesses the current ubiquo_user from the session.
    # Set it to :false if login fails so that future calls do not hit the database.
    def current_ubiquo_user
      #    @current_ubiquo_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || :false)
      @current_ubiquo_user ||= (login_from_session || login_from_cookie || :false)
    end

    # Store the given ubiquo_user in the session.
    def current_ubiquo_user=(new_ubiquo_user)
      session[:ubiquo] ||= {}
      session[:ubiquo][:ubiquo_user_id] = (new_ubiquo_user.nil? || new_ubiquo_user.is_a?(Symbol)) ? nil : new_ubiquo_user.id
      @current_ubiquo_user = new_ubiquo_user || :false
    end
    
    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    
    def login_required
      logged_in? || access_denied
    end
    
    # Filter method to enforce a superadmin login requirement.
    #
    # To require superadmin login for all actions, use this in your controllers:
    #
    #   before_filter :superadmin_required
    #
    # To require superadmin logins for specific actions, use this in your controllers:
    #
    #   before_filter :superadmin_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :superadmin_required
    #
    
    def superadmin_required
      (logged_in? && current_ubiquo_user.is_superadmin?) || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the ubiquo_user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to ubiquo_login_path
        end
        format.any(:js, :xml, :atom, :rss) do
          request_http_basic_authentication 'Web Password'
        end
      end
    end

    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_ubiquo_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_ubiquo_user, :logged_in?
    end

    # Attempt to login by the ubiquo_user id stored in the session.
    def login_from_session
      self.current_ubiquo_user = UbiquoUser.find_by_id(session[:ubiquo][:ubiquo_user_id]) if session[:ubiquo] && session[:ubiquo][:ubiquo_user_id]
    end

    # Attempt to login by an expiring token in the cookie.
    def login_from_cookie
      ubiquo_user = cookies[:auth_token] && UbiquoUser.find_by_remember_token(cookies[:auth_token])
      if ubiquo_user && ubiquo_user.remember_token?
        ubiquo_user.remember_me
        cookies[:auth_token] = { :value => ubiquo_user.remember_token, :expires => ubiquo_user.remember_token_expires_at }
        self.current_ubiquo_user = ubiquo_user
      end
    end

    # Handler to remove cookie login data on an unverified request (CVE-2011-0447)
    def handle_unverified_request
      super # call the default behaviour which resets the session
      cookies.delete(:auth_token) # remove the auto login cookie so the fraudulent request is rejected.
      raise ActionController::InvalidAuthenticityToken # added to detect possible problems when upgrading
    end

  end
end
