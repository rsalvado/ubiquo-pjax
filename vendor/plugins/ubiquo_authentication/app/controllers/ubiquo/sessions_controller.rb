class Ubiquo::SessionsController < ApplicationController

  Ubiquo::Extensions.load_extensions_for UbiquoController, self

  before_filter :cookies_required

  skip_before_filter :verify_authenticity_token, :only => [:create]

  filter_parameter_logging :password

  #shows the login form
  def new
    unless has_cookies_enabled?
      flash[:error] = t 'ubiquo.auth.cookies_error'
    end
    unless ubiquo_users?
      flash.now[:notice] = t 'ubiquo.auth.create_superadmin'
    end
    if logged_in?
      redirect_to ubiquo_home_path
    end
  end

  # login method. If OK, redirects to expected path or ubiquo_home.
  def create
    unless ubiquo_users?
      UbiquoUser.create_first(params[:login],params[:password])
    end
    self.current_ubiquo_user = UbiquoUser.authenticate(params[:login],
                                                       params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_ubiquo_user.remember_me
        cookies[:auth_token] = {
          :value => self.current_ubiquo_user.remember_token ,
          :expires => self.current_ubiquo_user.remember_token_expires_at
        }
      end
      flash.discard
      redirect_back_or_default(ubiquo_home_path)
    else
      flash[:error] = t 'ubiquo.auth.login_invalid'
      render :action => 'new'
    end
  end
  # logout method. Destroy all ubiquo_user data and send ubiquo_user
  # to ubiquo_home (which commonly is login_required)
  def destroy
    self.current_ubiquo_user.forget_me if logged_in?
    cookies.delete :auth_token
    session.delete(:ubiquo)
    flash[:notice] = t 'ubiquo.auth.logout'
    redirect_back_or_default(ubiquo_home_path)
  end

  protected

  def ubiquo_users?
    Rails.env.production? || UbiquoUser.count > 0
  end

  def cookies_required
    return if has_cookies_enabled?
    unless cookie_redirected?
      redirect_to(ubiquo_login_path(:cookies => true))
      return false
    end
  end

  def has_cookies_enabled?
    Rails.env.test? ||
      !request.cookies[ActionController::Base.session_options[:key]].to_s.blank?
  end

  # Returns true if we have been already redirected to the login form
  def cookie_redirected?
    params[:cookies].present?
  end

end
