require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::NavigationLinks::HelperTest < ActiveSupport::TestCase
  attr_accessor :params
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::CaptureHelper
  
  include Ubiquo::NavigationLinks
  include Ubiquo::NavigationLinks::Helpers
  
  def setup
    @params = {}
  end
    
  def test_presence_of_instance_methods
    %w{render_navigation_links_section create_link_navigator render_link_navigator}.each do |instance_method|
      assert respond_to?(instance_method), "#{instance_method} is not defined after including the helper" 
    end     
  end    

  def test_navigator_with_two_links
    expected = <<-END
       <ul id="links_for_navigation"><li><a href="http://www.foo.com">nana_link</a></li>\n<li><a href="http://www.new-foo.com">nene_link</a></li>\n</ul>      
    END
    
    navigator_instance = create_link_navigator(:id => "links_for_navigation", :link_options => {}) do |navigator|
      navigator.add_link do |link| 
        link.text = 'nana_link'
        link.url = "http://www.foo.com"
      end

      navigator.add_link do |link| 
        link.text = 'nene_link'
        link.url = "http://www.new-foo.com"
      end
    end
    generated_html = render_link_navigator(navigator_instance)

    assert_equal expected.strip, generated_html;
  end
  
end
