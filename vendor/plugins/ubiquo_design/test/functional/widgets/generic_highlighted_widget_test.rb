require File.dirname(__FILE__) + '/../../test_helper'

class GenericHighlightedWidgetTest < ActionController::TestCase
  tests PagesController

  test "generic_highlighted widget should get show" do
    widget, page = create_widget(:generic_highlighted)
    GenericHighlighted.any_instance.expects(:elements).returns([])
    get :show, :url => page.url_name
    assert_response :success
    assert_equal widget_attributes[:title], assigns(:title)
    assert_equal widget_attributes[:model], assigns(:model)
    assert_kind_of Array, assigns(:elements)
  end

  test "generic_highlighted widget view should be as expected" do
    widget, page = create_widget(:generic_highlighted)
    get :show, :url => page.url_name
    assert_select "div.generic-highlighted.generichighlighted-highlighted" do
      assert_select 'h3', widget_attributes[:title]
      assert_select "div.carousel-wrapper" do
        assert_select 'ul.carousel-content' do
          assert_select "li.slide", GenericHighlighted.count
        end
      end
      assert_select "ul.highlighted-paginator"
    end
  end

  private

  def widget_attributes
    {
      :model => 'GenericHighlighted',
      :title => 'title',
    }  
  end
  
  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
