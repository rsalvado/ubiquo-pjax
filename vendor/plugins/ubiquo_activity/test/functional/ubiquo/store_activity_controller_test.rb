require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::StoreActivityControllerTest < ActionController::TestCase
  
  def test_should_register_successful_activity_info_in_create
    ActivityInfo.delete_all  
    assert_difference 'ActivityInfo.count' do
      login_as(:josep)
      post :create
    end
    assert_equal "successful", ActivityInfo.first.status
    assert_equal "ubiquo/store_activity", ActivityInfo.first.controller
    assert_equal "create", ActivityInfo.first.action
    assert_equal ubiquo_users(:josep).id, ActivityInfo.first.ubiquo_user_id
  end
  
  def test_should_register_info_activity_info_in_publish
    ActivityInfo.delete_all      
    assert_difference 'ActivityInfo.count' do
      login_as(:eduard)
      put :publish
    end
    assert_equal "info", ActivityInfo.first.status
    assert_equal "ubiquo/store_activity", ActivityInfo.first.controller
    assert_equal "publish", ActivityInfo.first.action
    assert_equal ubiquo_users(:eduard).id, ActivityInfo.first.ubiquo_user_id    
  end
  
  def test_should_register_error_activity_info_in_destroy
    ActivityInfo.delete_all      
    assert_difference 'ActivityInfo.count' do
      login_as(:eduard)
      delete :destroy
    end
    assert_equal "error", ActivityInfo.first.status
    assert_equal "ubiquo/store_activity", ActivityInfo.first.controller
    assert_equal "destroy", ActivityInfo.first.action
    assert_equal ubiquo_users(:eduard).id, ActivityInfo.first.ubiquo_user_id
  end
end

class Ubiquo::StoreActivityController < UbiquoController
  def create
    respond_to do |format|
      store_activity :successful, { :title => "Test object - 12/06/09" }
      format.html { render :nothing => true }
    end
  end
  
  def publish
    respond_to do |format|
      store_activity :info, { :message => "Test object published correctly" }
      format.html { render :nothing => true }
    end
  end
  
  def destroy
    respond_to do |format|
      store_activity :error, { :object_type => "Test", :object_id => 23 }
      format.html { render :nothing => true }
    end
  end
end

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end
