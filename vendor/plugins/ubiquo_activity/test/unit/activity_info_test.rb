require File.dirname(__FILE__) + "/../test_helper.rb"

class ActivityInfoTest < ActiveSupport::TestCase

  test "should create activity info" do
    assert_difference "ActivityInfo.count" do
      activity_info = create_activity_info
      assert !activity_info.new_record?, "#{activity_info.errors.full_messages.to_sentence}"
    end
  end
  
  test "should create activity info with related object" do
    assert_difference "ActivityInfo.count" do
      activity_info = create_activity_info(:related_object_id => ubiquo_users(:josep).id,
                                           :related_object_type => "UbiquoUser",
                                           :action => 'update')
      assert !activity_info.new_record?, "#{activity_info.errors.full_messages.to_sentence}"
    end    
  end

  test "should require controller" do
    assert_no_difference "ActivityInfo.count" do
      activity = create_activity_info :controller => nil
      assert activity.errors.on(:controller)
    end
  end
  
  test "should require action" do
    assert_no_difference "ActivityInfo.count" do
      activity = create_activity_info :action => nil
      assert activity.errors.on(:action)
    end
  end
  
  test "should require status" do
    assert_no_difference "ActivityInfo.count" do
      activity = create_activity_info :status => nil
      assert activity.errors.on(:status)
    end
  end
  
  test "should require ubiquo_user_id" do
    assert_no_difference "ActivityInfo.count" do
      activity = create_activity_info :ubiquo_user_id => nil
      assert activity.errors.on(:ubiquo_user_id)
    end
  end  
  
  test "should filter by date" do
    ActivityInfo.delete_all
    activity1 = create_activity_info :created_at => 4.days.ago
    activity2 = create_activity_info :created_at => 2.days.ago
    fake_activity = create_activity_info
    searched_activities = ActivityInfo.filtered_search({ :date_start => 3.days.ago,
                                                       :date_end => 1.days.ago,
                                                     })                                       
    assert_equal_set [activity2], searched_activities
  end
  
  test "should filter by user" do
    ActivityInfo.delete_all
    searched_user = UbiquoUser.find_by_login("josep")
    activity1 = create_activity_info :ubiquo_user => searched_user
    activity2 = create_activity_info :ubiquo_user => UbiquoUser.find_by_login("eduard")
    searched_activities = ActivityInfo.filtered_search(:user => searched_user.id)
    assert_equal_set [activity1], searched_activities
    assert_equal_set [], ActivityInfo.filtered_search(:user => '100')
  end

  private
  
  def create_activity_info(options = { })
    default_options = {
      :controller => "tests_controller",
      :action => "create",
      :status => "successful",
      :ubiquo_user_id => 3,
    }
    ActivityInfo.create(default_options.merge(options))
  end
end
