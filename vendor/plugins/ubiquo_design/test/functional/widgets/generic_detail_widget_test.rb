require File.dirname(__FILE__) + '/../../test_helper'

class GenericDetailWidgetTest < ActionController::TestCase
  tests PagesController

  test "generic_detail widget should get show" do
    widget, page = create_widget(:generic_detail)
    visited_item = GenericDetail.first
    GenericDetail.any_instance.expects(:element).returns(visited_item)
    get :show, :url => page.url_name, :id => visited_item.id
    assert_response :success
    assert_equal visited_item, assigns(:element)
  end

  test "generic_detail widget view should be as expected" do
    widget, page = create_widget(:generic_detail)
    get :show, :url => [page.url_name, widget.id]
    assert_select "div.genericdetail-detail.generic-detail" do
      assert_select 'h3', widget.name
      assert_select 'div.content'
    end
  end

  private

  def widget_attributes
    {
      :model => 'GenericDetail'
    }
  end
  
  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
