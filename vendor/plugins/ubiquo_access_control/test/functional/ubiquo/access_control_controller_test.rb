require File.dirname(__FILE__) + "/../../test_helper.rb"

class AccessControlControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_redirection_when_not_logged_in
    @request.session[:ubiquo] ||= {}
    @request.session[:ubiquo][:ubiquo_user_id] = nil
    get :admin
    assert_redirected_to ubiquo_login_path
  end

  def test_should_permit_admin
    login_as :admin

    get :admin
    assert_response :success

    get :permit, :perm => :admin
    assert_response :success

    get :restrict, :perm => :admin
    assert_response :success
  end

  def test_should_permit_simple_action
    roles(:role_1).add_permission :permission_1
    ubiquo_users(:josep).add_role :role_1
    login_as :josep

    get :simple
    assert_response :success

    get :permit, :perm => :simple
    assert_response :success

    get :restrict, :perm => :simple
    assert_response :success
  end

  def test_shouldnt_permit_simple_action
    login_as :josep

    get :simple
    assert_response 403

    get :permit, :perm => :simple
    assert_response 403

    get :restrict, :perm => :simple
    assert_response 403
  end
  
  
  def test_should_permit_super_admin
    ubiquo_users(:admin).update_attribute(:is_superadmin, true)
    login_as :admin

    get :admin
    assert_response :success

    get :permit, :perm => :admin
    assert_response :success

    get :restrict, :perm => :admin
    assert_response :success
  end
  
  def test_should_permit_super_admin
    login_as :admin

    get :admin
    assert_response :success

    get :permit, :perm => :admin
    assert_response :success

    get :restrict, :perm => :admin
    assert_response :success
  end
  
end

# This controller is just for test purposes it can be safely be deleted.
class AccessControlController < UbiquoController

  @@permissions = {
    :admin  => nil,
    :simple => "permission_1",
    :super_admin => {:admin => false}
  }
  access_control @@permissions


  def index
    render :inline=>"Hello!"
  end

  def admin
    index
  end

  def super_admin
    index
  end

  def simple
    index
  end

  def permit
    if permit?(@@permissions[params[:perm]])
      render :text => "OK"
    else
      render :text => "KO", :status => 403
    end
  end

  def restrict
    a=true
    restrict_to(@@permissions[params[:perm]]) do
      a=false
      render :text => "OK"
    end
    if a
      render :text => "KO", :status => 403
    end
  end

end
