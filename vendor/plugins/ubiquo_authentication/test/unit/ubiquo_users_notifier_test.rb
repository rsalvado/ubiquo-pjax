require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoUsersNotifierTest < ActionMailer::TestCase
  #tests UbiquoUsersNotifier

  use_ubiquo_fixtures
  
  def test_should_send_forgot_password
    ubiquo_user = UbiquoUser.first
    ubiquo_user.reset_password!
    
    assert ActionMailer::Base.deliveries.empty? 
    email = UbiquoUsersNotifier.deliver_forgot_password(ubiquo_user, "localhost:3000")
    assert !ActionMailer::Base.deliveries.empty? 
    
    assert_equal [ubiquo_user.email], email.to
    assert_match ubiquo_user.password , email.body
    assert_match /#{ubiquo_user.login}/ , email.body
    assert_match /#{Ubiquo::Config.get(:app_title)}/ , email.subject
  end
  
  def test_should_send_confirm_creation
    ubiquo_user = UbiquoUser.first
    ubiquo_user.reset_password!
    
    assert ActionMailer::Base.deliveries.empty? 
    email = UbiquoUsersNotifier.deliver_confirm_creation(ubiquo_user, "Welcome message", "localhost:3000")
    assert !ActionMailer::Base.deliveries.empty? 
    
    assert_equal [ubiquo_user.email], email.to
    assert_match ubiquo_user.password , email.body
    assert_match /#{ubiquo_user.login}/ , email.body
    assert_match /#{Ubiquo::Config.get(:app_title)}/ , email.subject
    assert_match /Welcome message/ , email.body
  end
    
#   test "forgot_password" do
#     @expected.subject = 'UbiquoUsersNotifier#forgot_password'
#     @expected.body    = read_fixture('forgot_password')
#     @expected.date    = Time.now

#     assert_equal @expected.encoded, UbiquoUsersNotifier.create_forgot_password(@expected.date).encoded
#   end

#   test "confirm_creation" do
#     @expected.subject = 'UbiquoUsersNotifier#confirm_creation'
#     @expected.body    = read_fixture('confirm_creation')
#     @expected.date    = Time.now
    
#     assert_equal @expected.encoded, UbiquoUsersNotifier.create_confirm_creation(@expected.date).encoded
#   end

end
