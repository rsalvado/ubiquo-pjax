require File.dirname(__FILE__) + '/../../test_helper'

class GenericListingWidgetTest < ActionController::TestCase
  tests PagesController

  test "generic_listing widget should get show" do
    widget, page = create_widget(:generic_listing)
    GenericListing.any_instance.expects(:elements).returns([])
    get :show, :url => page.url_name
    assert_response :success
    assert_equal widget_attributes[:title], assigns(:title)
    assert_equal widget_attributes[:model], assigns(:model)
    assert_equal widget_attributes[:show_images], assigns(:show_images)
    assert_kind_of Array, assigns(:elements)
  end

  test "generic_listing widget view should be as expected" do
    widget, page = create_widget(:generic_listing)
    get :show, :url => page.url_name
    assert_select "div.genericlisting-list.generic-main-list" do
      assert_select 'h3', widget_attributes[:title]
      assert_select 'ul' do
        assert_select "li", GenericListing.count do
          assert_select "h4"
          assert_select "div.content"
        end
      end
    end
  end

  private

  def widget_attributes
    {
      :model => 'GenericListing',
      :title => 'title',
      :show_images => true,
    }  
  end
  
  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
