require File.dirname(__FILE__) + "/../../test_helper.rb"
require 'ubiquo/passwords_controller'

class Ubiquo::PasswordsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_reset_password
    
    UbiquoUser.any_instance.expects("reset_password!")
    UbiquoUsersNotifier.expects(:deliver_forgot_password).once.returns(nil)
    u = UbiquoUser.first
    post :create, :email => u.email
    assert_redirected_to new_ubiquo_session_path
    
  end
  
  def test_should_reset_valid_emails
    
    u = UbiquoUser.first
    post :create, :email => "invalid.#{u.email}"
    assert_response :success
    
  end
end
