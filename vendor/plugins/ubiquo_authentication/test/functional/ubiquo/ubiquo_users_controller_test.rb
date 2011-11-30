require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::UbiquoUsersControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:ubiquo_users)
  end
  
  def test_should_get_index_with_custom_i18n_locale
    user = ubiquo_users(:admin)
    login_as user
    I18n.locale = 'invalid_locale'
    assert_not_equal I18n.locale, user.locale
    assert_not_equal 'es', I18n.locale
    user.update_attribute :locale, 'es'
    get :index
    assert_response :success
    assert_equal 'es', I18n.locale.to_s
  end
  
  def test_should_get_index_with_default_i18n_locale
    user = ubiquo_users(:admin)
    login_as user
    assert_nil user.locale
    I18n.locale = 'invalid_locale'
    assert_not_equal Ubiquo.default_locale, I18n.locale
    get :index
    assert_response :success
    assert_equal Ubiquo.default_locale, I18n.locale
  end

  def test_shouldnt_get_index_without_permission
    login_as :josep
    get :index
    assert_response :forbidden
  end
  
  def test_should_get_index_filtered_by_admin
    admin_ubiquo_users = [ubiquo_users(:admin)]
    get :index, :filter_admin => "1"
    assert UbiquoUser.filtered_search({"filter_admin" => "true"}).to_set == admin_ubiquo_users.to_set
    non_admin_ubiquo_users = [ubiquo_users(:josep), ubiquo_users(:inactive), ubiquo_users(:eduard)]
    get :index, :filter_admin => "0"
    assert UbiquoUser.filtered_search({"filter_admin" => "false"}).to_set == non_admin_ubiquo_users.to_set
  end  

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_get_edit
    get :edit, :id => ubiquo_users(:josep).id
    assert_response :success
  end

  def test_should_create_ubiquo_user
    UbiquoUsersNotifier.expects(:deliver_confirm_creation).once.returns(nil)
    assert_difference('UbiquoUser.count') do
      post :create, :send_confirm_creation => "1", :ubiquo_user => { :name => "name", :surname => "surname", :login => 'ubiquo_userlogin', :email => "test@test.com", :password => '123456', :password_confirmation => '123456', :is_admin => false, :is_active => false}
    end

    assert_redirected_to ubiquo_ubiquo_users_path
  end
  
  def test_shouldnt_create_ubiquo_user_if_wrong_ubiquo_user
    UbiquoUsersNotifier.expects(:deliver_confirm_creation).never
    assert_no_difference('UbiquoUser.count') do
      post :create, :ubiquo_user => { :login => nil }
    end

    assert_template "new"
  end

  def test_should_update_ubiquo_user
    put :update, :id => ubiquo_users(:josep).id, :ubiquo_user => { :name => "name", :surname => "surname", :login => 'newlogin', :email => "test@test.com", :password => 'newpass', :password_confirmation => 'newpass', :is_admin => false, :is_active => false}
    assert_redirected_to ubiquo_ubiquo_users_path
  end
  
  def test_shouldnt_update_ubiquo_user_if_wrong_fields
    put :update, :id => ubiquo_users(:josep).id, :ubiquo_user => { :login => nil}
    assert_template "edit"
  end

  def test_should_destroy_ubiquo_user
    assert_difference('UbiquoUser.count', -1) do
      delete :destroy, :id => ubiquo_users(:josep).id
    end

    assert_redirected_to ubiquo_ubiquo_users_path
  end
  
  def test_should_update_permissions
    
    put :update, :id => ubiquo_users(:josep).id, :ubiquo_user => {:role_ids => Role.find(:all).map(&:id)}
    assert_equal ubiquo_users(:josep).roles.size, Role.count
  end

  def test_should_not_create_admin_if_no_admin
    user = ubiquo_users(:josep)
    set_user_management user
    login_as user

    assert_no_difference('UbiquoUser.count') do
      post :create,  :ubiquo_user => { :name => "name", :surname => "surname", :login => 'ubiquo_userlogin', :email => "test@test.com", :password => '123456', :password_confirmation => '123456', :is_admin => true, :is_active => false}
    end
  end

  def test_should_not_update_admin_if_no_admin
    user = ubiquo_users(:josep)
    set_user_management user
    login_as user

    put :update, :id => ubiquo_users(:inactive).id, :ubiquo_user => {:is_admin => true, :is_active => true}

    m_user = UbiquoUser.find_by_login('inactive')
    assert m_user.is_admin == false
    assert m_user.is_active == false
  end
 
  def test_should_not_destroy_admin_if_no_admin
    user = ubiquo_users(:josep)
    set_user_management user
    login_as user

    assert_no_difference('UbiquoUser.count') do
      delete :destroy, :id => ubiquo_users(:admin).id
    end
    
  end

  protected

  def set_user_management user
    r = Role.create(:name => 'user_management')
    r.permissions << Permission.create(:name => 'Ubiquo User management', :key => 'ubiquo_user_management')
    r.save
    user.roles << r
    user.save
  end
end
