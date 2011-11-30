require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class BaseTest < ActiveSupport::TestCase
   
    test "load page is a page" do 
      p = Page.published.first
      PagesController.any_instance.stubs(:params => { :url => p.url_name })
      assert PagesController.new.uhook_load_page.is_a?(Page)
    end
    
    test "find widget is a widget" do
      c = widgets(:one)
      Ubiquo::WidgetsController.any_instance.stubs(:params => {:id => c.id}, :session => {})
      begin
        assert Ubiquo::WidgetsController.new.uhook_find_widget.is_a?(Widget)
      rescue ActiveRecord::RecordNotFound => e
        assert true
      end
    end
    
    test "prepare widget returns a widget" do
      c = widgets(:one)
      Ubiquo::WidgetsController.any_instance.stubs(:params => {}, :session => {})
      assert Ubiquo::WidgetsController.new.uhook_prepare_widget(c).is_a?(Widget)
    end
    
    test "destroy widget should destroy one widget at least" do
      c = widgets(:one)
      c.class.any_instance.expects(:destroy).at_least(1)
      Ubiquo::WidgetsController.new.uhook_destroy_widget(c)
    end
    
  end
end
