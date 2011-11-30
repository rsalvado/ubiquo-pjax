class Ubiquo::PasswordsController < ApplicationController

  Ubiquo::Extensions.load_extensions_for UbiquoController, self
  
  #shows the request pasword recovering form.
  def new
  end

  #resets the password of the user(finded by e-mail)
  def create
    @user = UbiquoUser.find_by_email(params[:email])
    if(@user)
      @user.reset_password!
      UbiquoUsersNotifier.deliver_forgot_password(@user, request.host_with_port)
      
      flash[:notice] = t 'ubiquo.auth.password_reset'
      redirect_to new_ubiquo_session_path
    else
      flash[:error] = t 'ubiquo.auth.email_invalid'
      render :action => 'new'
    end
  end
end
