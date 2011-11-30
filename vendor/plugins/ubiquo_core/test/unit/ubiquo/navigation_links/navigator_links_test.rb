require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::NavigationLinks::NavigatorLinksTest < ActiveSupport::TestCase
  include Ubiquo::NavigationLinks
  
  EXPECTED_INSTANCE_METHODS = %w{add_link}
  
  def setup    
  end
     
  def test_initialize
    navigator = NavigatorLinks.new :class => 'dummy_class_name'
    assert navigator
    assert_equal 'dummy_class_name', navigator.html_options[:class]
  end
  
  def test_add_link_to_navigator_with_option_for_links
    navigator = NavigatorLinks.new :link_options => {:class => 'dummy_class_name'}
    navigator.add_link do |link|
    end
    assert_equal 1, navigator.links.size
    assert_equal "dummy_class_name", navigator.links[0].class
  end
  
  def test_add_link_to_navigator_without_options_for_links
    navigator = NavigatorLinks.new :class => 'dummy_class_name'
    navigator.add_link do |link|
    end
    assert_equal 1, navigator.links.size
    assert_nil navigator.links[0].class
  end

  def test_presence_of_instance_methods
    navigator = NavigatorLinks.new :class => 'dummy_class_name'
    EXPECTED_INSTANCE_METHODS.each do |method|
      assert navigator.respond_to?(method), "#{method} is not defined in #{navigator.inspect} (#{navigator.class})" 
    end     
  end
  
end
