require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoUserRoleTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
    
  def test_should_create_ubiquo_user_role
    assert_difference "UbiquoUserRole.count" do
      ur = create_ubiquo_user_role
      assert !ur.new_record?, "#{ur.errors.full_messages.to_sentence}"
    end
  end
  
  
  protected
  def create_ubiquo_user_role(options = {})
    UbiquoUserRole.create({ :ubiquo_user => UbiquoUser.find(:first), :role=>Role.find(:first) }.merge(options))
  end

end
