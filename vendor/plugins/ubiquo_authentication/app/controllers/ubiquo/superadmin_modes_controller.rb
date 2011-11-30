class Ubiquo::SuperadminModesController < UbiquoController

  #put the current_ubiquo_user in superadmin mode if can go to that mode.
  def create
    session[:superadmin_mode] = current_ubiquo_user.is_superadmin?
    redirect_to_home
  end
  
  #returns from superadmin mode to normal mode.
  def destroy
    session[:superadmin_mode] = false
    redirect_to_home
  end
  
  private
  
  #send a redirect to the correct home, superadmin home if in superadmin mode or normal home if in normal mode
  def redirect_to_home
    redirect_to session[:superadmin_mode] ? ubiquo_superadmin_home_path : ubiquo_home_path
  end
end
