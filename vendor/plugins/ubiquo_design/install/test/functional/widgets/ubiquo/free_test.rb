require File.dirname(__FILE__) + '/../../../test_helper'

class FreeWidgetUbiquoTest < ActionController::TestCase
  tests Ubiquo::WidgetsController

  test "edit new form" do
    login_as
    widget, page = create_widget(:free)
    get :show, :page_id => page.id,
               :id => widget.id
    assert_response :success
  end

  test "edit form" do
    login_as
    widget, page = create_widget(:free)
    get :show, :page_id => page.id,
               :id => widget.id
    assert_response :success
  end

  test "form submit" do
    login_as
    widget, page = create_widget(:free)
    xhr :post, :update, :page_id => page.id,
                        :id => widget.id,
                        :widget => widget_attributes
    assert_response :success
  end

  test "form submit with errors" do
    login_as
    widget, page = create_widget(:free)
    xhr :post, :update, :page_id => page.id,
                        :id => widget.id,
                        :widget => { :content => '' }
    assert_response :success
    assert_select_rjs "error_messages"
  end

  private

  def widget_attributes
    {
      :content => 'Example content',
    }
  end

  def create_widget(type, options = {})
    insert_widget_in_page(type, widget_attributes.merge(options))
  end

end
