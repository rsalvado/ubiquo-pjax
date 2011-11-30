require File.dirname(__FILE__) + "/../test_helper.rb"
require 'mocha'

class StoreActivityTest < ActiveSupport::TestCase
  include UbiquoActivity::StoreActivity
  
  def setup
    self.stubs(:request_activity_options).returns({
      :controller => "tests",
      :action => "show",
      :ubiquo_user_id => 1,
    })
  end
  
  def test_should_create_with_related_model_complete
    ActivityInfo.delete_all
    object = ubiquo_users(:eduard)
    assert_difference "ActivityInfo.count" do
      store_activity :successful, object
    end
    assert_equal 1, ActivityInfo.count
    assert_equal ubiquo_users(:eduard).id, ActivityInfo.first.related_object_id
    assert_equal "UbiquoUser", ActivityInfo.first.related_object_type
    assert_equal "successful", ActivityInfo.first.status
  end
  
  def test_should_create_successful_activity_info
    ActivityInfo.delete_all
    assert_difference "ActivityInfo.count" do
      store_activity :successful
    end
    assert_equal 1, ActivityInfo.count
    assert_equal "successful", ActivityInfo.first.status
  end
  
  def test_should_create_info_activity_info
    ActivityInfo.delete_all
    assert_difference "ActivityInfo.count" do
      store_activity :info
    end
    assert_equal 1, ActivityInfo.count
    assert_equal "info", ActivityInfo.first.status    
  end
  
  def test_should_create_error_activity_info
    ActivityInfo.delete_all
    assert_difference "ActivityInfo.count" do
      store_activity :error
    end
    assert_equal 1, ActivityInfo.count
    assert_equal "error", ActivityInfo.first.status    
  end
  
  def test_should_create_activity_info_without_additional_info
    ActivityInfo.delete_all
    assert_difference "ActivityInfo.count" do    
      store_activity :info
    end
    assert_equal 1, ActivityInfo.count
    info = YAML::load(ActivityInfo.first.info)
    assert info.blank?
  end  
  
  def test_should_create_activity_info_with_additional_info
    ActivityInfo.delete_all
    assert_difference "ActivityInfo.count" do    
      store_activity :info, { :message => "Test message" }
    end
    assert_equal 1, ActivityInfo.count
    info = YAML::load(ActivityInfo.first.info)
    assert_equal_set [:message], info.keys
    assert_equal "Test message", info[:message]
  end
  
end
