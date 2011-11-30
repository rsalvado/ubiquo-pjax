require File.dirname(__FILE__) + "/../../test_helper.rb"
class Ubiquo::SuperadminModesControllerTest < ActionController::TestCase
  
  def test_should_create
    login_as :admin
    post :create
    
    assert_equal true, session[:superadmin_mode]

  end
  
  def test_should_destroy
    get :destroy
    assert_equal false, session[:superadmin_mode]
  end
  
end
