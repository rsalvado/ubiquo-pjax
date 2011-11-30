require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::NavigationTabs::HelperTest < ActiveSupport::TestCase
  attr_accessor :params
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::CaptureHelper
  
  include Ubiquo::NavigationTabs
  include Ubiquo::NavigationTabs::Helpers
  
  def setup
    @params = {}
  end
    
  def test_presence_of_instance_methods
    %w{render_navigation_tabs_section create_tab_navigator render_tab_navigator}.each do |instance_method|
      assert respond_to?(instance_method), "#{instance_method} is not defined after including the helper" 
    end     
  end    

  def test_navigator_with_two_tabs
    expected = <<-END
       <ul id="contents_navtabs"><li><a href="http://www.foo.com">nana_tab</a></li>\n<li><a href="http://www.new-foo.com">nene_tab</a></li>\n</ul>
    END
    navigator_instance = create_tab_navigator(:id => "contents_navtabs", :tab_options => {}) do |navigator|
      navigator.add_tab do |tab| 
        tab.text = 'nana_tab'
        tab.link = "http://www.foo.com"
      end

      navigator.add_tab do |tab| 
        tab.text = 'nene_tab'
        tab.link = "http://www.new-foo.com"
      end
    end
    generated_html = render_tab_navigator(navigator_instance)
    
    assert_equal expected.strip, generated_html;
  end
  
end
