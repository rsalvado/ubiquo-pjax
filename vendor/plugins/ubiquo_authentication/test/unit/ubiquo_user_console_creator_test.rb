require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoUserConsoleCreatorTest < ActiveSupport::TestCase

  def setup
    UbiquoUser.destroy_all
  end
  
  # This ensures we don't miss the rake ubiquo:create_user task when updating the UbiquoUser required fields
  def test_should_be_able_to_create_a_user
    assert_difference 'UbiquoUser.count' do
      ubiquo_user = create_user
      assert !ubiquo_user.new_record?, "#{ubiquo_user.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_be_able_to_create_a_superadmin_user
    ubiquo_user = create_user :is_superadmin => true
    assert ubiquo_user.is_superadmin?
  end
  
  private
  
  def create_user(options={})
    options.reverse_merge!({ 
      :login => 'login',
      :password => 'password',
      :password_confirmation => 'password',
      :name => 'myname',
      :surname => 'mysurname1 mysurname2',
      :email => 'myemail@test.com',
      :is_active => true,
      :is_admin => true,
      :is_superadmin => true
    })
    UbiquoAuthentication::UbiquoUserConsoleCreator.create! options 
  end
  
end
