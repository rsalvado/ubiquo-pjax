require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::NavigationLinks::LinkTest < ActiveSupport::TestCase
  include Ubiquo::NavigationLinks
  
  EXPECTED_INSTANCE_METHODS = %w{url url_if has_url? is_highlighted? highlights_on title class is_disabled?}
  
  def setup    
    
    @text = 'my_text'
    @title = 'my_link'
    @other_title = 'my_second_link'
    @url = "http://www.foo.com"
    @new_url = "http://www.new-foo.com"
   
    @link = Link.new :text => @text, :url => @url, :title => @title
  end
     
  def test_initialize
    link = Link.new :text => 'dummy_text'
    assert link
    assert_equal 'dummy_text', link.text
  end
  
  def test_initialize_with_highlights
    link = Link.new :title => 'test', :highlights => [{:action => 'edit'}, {:action => 'index'}]
    assert_kind_of Array, link.highlights
    assert_equal 2, link.highlights.size
    assert_kind_of Hash, link.highlights[0]
    assert_kind_of Hash, link.highlights[1]
  end
  
  def test_initialize_with_one_highlight
    link = Link.new :name => 'test', :highlights => {:action => 'edit'}
    assert_kind_of Array, link.highlights
    assert_equal 1, link.highlights.size
    assert_kind_of Hash, link.highlights[0]
  end
  
    
  def test_presence_of_instance_methods
    EXPECTED_INSTANCE_METHODS.each do |method|
      assert @link.respond_to?(method), "#{method} is not defined in #{@link.inspect} (#{@link.class})" 
    end     
  end
  
  def test_assigns_html_title
    assert_equal 'my_link', @link.html[:title]
       @link.title= @other_title 
    assert_equal 'my_second_link', @link.html[:title]
  end
  
  def test_url_assigns_if_url_is_null
    assert_equal(@url, @link.url)
    @link.url(@new_url)
    assert_equal("http://www.foo.com", @link.url)
  end

  def test_url_NOT_assigns_if_url_is_NOT_null
    link = Link.new :title => 'new_link', :highlights => {:controller => 'nana'}
    assert_nil link.url
    link.url(@new_url)
    assert_equal("http://www.new-foo.com", link.url)
  end

  
  def test_is_highlighted?
    link = Link.new :title => 'new_link', :highlights => {:controller => 'nana'}
    assert link.is_highlighted?({:controller => 'nana'})
  end

  def test_is_disabled?
    link = Link.new :title => 'new_link', :highlights => {:controller => 'nana'}, :disabled => true
    assert link.disabled
  end
end
