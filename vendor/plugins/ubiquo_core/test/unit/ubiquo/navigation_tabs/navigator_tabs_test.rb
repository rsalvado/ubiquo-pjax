require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::NavigationTabs::NavigatorTabsTest < ActiveSupport::TestCase
  include Ubiquo::NavigationTabs
  
  EXPECTED_INSTANCE_METHODS = %w{add_tab sort!}
  
  def setup    
  end
     
  def test_initialize
    navigator = NavigatorTabs.new :class => 'dummy_class_name'
    assert navigator
    assert_equal 'dummy_class_name', navigator.html_options[:class]
  end
  
  def test_add_tab_to_navigator_with_option_for_tabs
    navigator = NavigatorTabs.new :tab_options => {:class => 'dummy_class_name'}
    navigator.add_tab do |tab|
    end
    assert_equal 1, navigator.tabs.size
    assert_equal "dummy_class_name", navigator.tabs[0].class
  end
  
  def test_add_tab_to_navigator_without_options_for_tabs
    navigator = NavigatorTabs.new :class => 'dummy_class_name'
    navigator.add_tab do |tab|
    end
    assert_equal 1, navigator.tabs.size
    assert_nil navigator.tabs[0].class
  end

  def test_presence_of_instance_methods
    navigator = NavigatorTabs.new :class => 'dummy_class_name'
    EXPECTED_INSTANCE_METHODS.each do |method|
      assert navigator.respond_to?(method), "#{method} is not defined in #{navigator.inspect} (#{navigator.class})" 
    end     
  end
  
end
