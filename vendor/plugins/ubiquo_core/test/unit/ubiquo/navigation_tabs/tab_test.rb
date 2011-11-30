require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::NavigationTabs::TabTest < ActiveSupport::TestCase
  include Ubiquo::NavigationTabs
  
  EXPECTED_INSTANCE_METHODS = %w{link link_if has_link? is_highlighted? highlights_on id title class}
  
  def setup    
    @title = 'my_tab'
    @other_title = 'my_second_tab'
   
    @tab = Tab.new :title => @title, :link => "http://www.foo.com"
  end
     
  def test_initialize
    tab = Tab.new :title => 'dummy_title'
    assert tab
    assert_equal 'dummy_title', tab.title
  end
  
  def test_initialize_with_highlights
    tab = Tab.new :title => 'test', :highlights => [{:action => 'edit'}, {:action => 'index'}]
    assert_kind_of Array, tab.highlights
    assert_equal 2, tab.highlights.size
    assert_kind_of Hash, tab.highlights[0]
    assert_kind_of Hash, tab.highlights[1]
  end
  
  def test_initialize_with_one_highlight
    tab = Tab.new :name => 'test', :highlights => {:action => 'edit'}
    assert_kind_of Array, tab.highlights
    assert_equal 1, tab.highlights.size
    assert_kind_of Hash, tab.highlights[0]
  end
  
    
  def test_presence_of_instance_methods
    EXPECTED_INSTANCE_METHODS.each do |method|
      assert @tab.respond_to?(method), "#{method} is not defined in #{@tab.inspect} (#{@tab.class})" 
    end     
  end
  
  def test_assigns_title
    assert_equal 'my_tab', @tab.title
       @tab.title= @other_title 
    assert_equal 'my_second_tab', @tab.title
  end
  
  def test_assigns_links
    assert_equal("http://www.foo.com", @tab.link)
    @tab.link= "http://www.new-foo.com"
    assert_equal("http://www.new-foo.com", @tab.link)
  end
  
  def test_is_highlighted?
    tab = Tab.new :title => 'new_tab', :highlights => {:controller => 'nana'}
    assert tab.is_highlighted?({:controller => 'nana'})
  end

end
