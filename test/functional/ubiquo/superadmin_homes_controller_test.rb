require File.dirname(__FILE__) + "/../../test_helper.rb"
class Ubiquo::SuperadminHomesControllerTest < ActionController::TestCase
  
  test "should get show if superadmin" do
    
    user = UbiquoUser.find(login_as(:superadmin))

    assert user.is_superadmin?
    
    get :show
    
    assert_response :ok
  end
  
  test "shouldnt get show if not superadmin" do
    user = UbiquoUser.find(login_as(:eduard))
    assert !user.is_superadmin?
    
    get :show
    
    assert_redirected_to ubiquo_login_path
  end
end
