require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::RolesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  def test_should_get_index_with_permission
    login_with_permission :role_management
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  def test_should_not_get_index_without_permission
    login_with_permission 
    get :index
    assert_response :forbidden
  end
  
  def test_should_get_new
    get :new
  end

  def test_should_create_role
    assert_difference('Role.count') do
      post :create, :role => { :name => "Test role"}
    end

    assert_redirected_to ubiquo_roles_path
  end

  def test_should_create_role_with_permissions
    assert_difference('Role.count') do
      assert_difference('RolePermission.count') do
        post :create, :role => { :name => "Test role"}, :permissions => [:permission_1]
      end
    end

    assert_redirected_to ubiquo_roles_path
  end
  
  def test_shouldnt_create_role_if_wrong_params
    assert_no_difference('Role.count') do
      assert_no_difference('RolePermission.count') do
        post :create, :role => { :name => nil}, :permissions => [:permission_1]
      end
    end
    assert_template "new"
  end

  def test_should_get_edit
    get :edit, :id => roles(:role_1).id
    assert_response :success
  end

  def test_should_update_role
    put :update, :id => roles(:role_1).id, :role => { :name =>"New name to the role" }
    assert_redirected_to ubiquo_roles_path
  end

  def test_should_update_role_permissions
    r=roles(:role_1)
    assert !r.has_permission?(:permission_1)
    put :update, {:id => r.id, :role => { }, :permissions => [:permission_1]}
    assert r.has_permission?(:permission_1)
    assert_redirected_to ubiquo_roles_path
  end

  def test_should_destroy_role
    assert_difference('Role.count', -1) do
      delete :destroy, :id => roles(:role_1).id
    end

    assert_redirected_to ubiquo_roles_path
  end
end
