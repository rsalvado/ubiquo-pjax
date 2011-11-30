require File.dirname(__FILE__) + '/../../test_helper'
require 'mocha'

class FreeWidgetTest < ActionController::TestCase
  tests PagesController

  test "free widget should load content" do
    widget, page = create_widget(:free)
    get :show, :url => page.url_name
    assert_response :success
    assert_equal widget_attributes[:content], assigns(:content), "Error on widget content"
  end

  test "free widget should have expected view" do
    widget, page = create_widget(:free)
    get :show, :url => page.url_name
    assert_select "div#example", {:count => 1, :text => 'Example content'}
  end

  private

  def widget_attributes
    {
      :content => '<div id="example">Example content</div>',
    }
  end

  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
