require File.dirname(__FILE__) + '/../../test_helper'

class StaticSectionWidgetTest < ActionController::TestCase
  tests PagesController

  test "static_section widget should get show" do
    widget, page = create_widget(:static_section)
    get :show, :url => page.url_name
    assert_response :success
    assert_equal widget_attributes[:title], assigns(:static_section).title, "Error on widget title"
  end

  test "static_section widget view should be as expected" do
    widget, page = create_widget(:static_section)
    get :show, :url => page.url_name
    assert_select "div.static-section" do
      assert_select "h2"
      assert_select "p.summary"
      assert_select "p.body"      
    end
  end

  if Ubiquo::Plugin.registered[:ubiquo_media]
    test "static_section widget with media attrs should get show" do
      widget, page = create_widget(:static_section, widget_media_attributes)
      get :show, :url => page.url_name
      assert_response :success
      assert_equal widget_attributes[:title], assigns(:static_section).title, "Error on widget title"
      assert_equal assets(:image), assigns(:image), "Error on widget image"
      assert_equal_set [assets(:video), assets(:doc)], assigns(:docs), "Error on widget docs"
    end

    test "static_section widget view with media attrs should be as expected" do
      widget, page = create_widget(:static_section, widget_media_attributes)
      get :show, :url => page.url_name
      assert_select "div.static-section" do
        assert_select "h2"
        assert_select "div.image"
        assert_select "p.summary"
        assert_select "p.body"
        assert_select "ul.docs" do
          assert_select "li", 2
        end
      end
    end
  else
    puts 'ubiquo_media not found, omitting StaticSection with media attributes tests'
  end
  
  private

  def widget_attributes
    {
      :title => 'About us (test company)',
    }
  end

  def widget_media_attributes
    {
      :image_ids => [assets(:image).id.to_s],
      :docs_ids => [assets(:video).id.to_s, assets(:doc).id.to_s],
    }
  end
  
  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
