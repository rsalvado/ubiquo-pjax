require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::UbiquoUserProfilesControllerTest < ActionController::TestCase
  def test_should_get_edit
    login_as ubiquo_users(:josep)
    get :edit
    assert_response :success
    assert_equal ubiquo_users(:josep).id, assigns(:ubiquo_user).id
  end
  
  def test_should_update_ubiquo_user
    login_as ubiquo_users(:josep)
    put :update, :ubiquo_user => { :name => "name", :surname => "surname", :email => "test@test.com", :password => 'newpass', :password_confirmation => 'newpass'}
    assert_redirected_to edit_ubiquo_ubiquo_user_profile_path
    assert_equal ubiquo_users(:josep).id, assigns(:ubiquo_user).id
  end
end
