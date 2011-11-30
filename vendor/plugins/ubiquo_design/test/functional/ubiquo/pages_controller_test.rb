require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::PagesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def setup
    login_as
  end

  def test_should_get_index
    get :index
    assert_response :success
    pages = assigns(:pages)
    assert_not_nil pages
    assert pages.size > 0
    pages.each do |page|
      assert_equal page.is_the_published?, false
    end
  end

  def test_shouldnt_get_index_without_permission
    login_as :eduard
    get :index
    assert_response :forbidden
  end

  def test_should_get_index_without_remove_for_keyed_pages
    get :index
    assert_select "tr#page_#{pages(:one_design).id}" do
      assert_select 'td:last-child a', :text => I18n.t('ubiquo.remove'), :count => 0
    end
    assert_select "tr#page_#{pages(:two_design).id}" do
      assert_select 'td:last-child a', :text => I18n.t('ubiquo.remove'), :count => 1
    end
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_get_new_with_possible_parent_pages
    get :new
    assert_response :success
    assert_not_equal [], assigns(:pages)
    draft_pages_without_home_page = Page.drafts - [pages(:one_design)]
    assert_equal_set draft_pages_without_home_page, assigns(:pages)
  end

  def test_should_get_new_without_possible_parent_pages
    Page.delete_all
    get :new
    assert_response :success
    assert_equal [], assigns(:pages)
  end

  def test_should_create_page_with_assigned_blocks
    assert_difference('Page.count') do
      post(:create,
           :page => {
             :name => "Custom page",
             :url_name => "custom_page",
             :page_template => "static"
           })
    end

    assert page = assigns(:page)
    assert_equal 2, page.blocks.size
    assert_equal ["top", "main"], page.blocks.map(&:block_type)
    assert_equal page.is_the_published?, false

    assert_redirected_to ubiquo_pages_path
  end

  def test_should_get_edit
    get :edit, :id => pages(:one).id
    assert_response :success
  end

  def test_should_update_page
    put(:update,
        :id => pages(:one).id,
        :page => {
          :name => "Custom page",
          :url_name => "custom_page",
          :page_template => "static"
        })
    assert_redirected_to ubiquo_pages_path
  end

  def test_should_destroy_page
    # if you remove a draft page, its published page is removed too
    assert_difference('Page.count', -2) do
      delete :destroy, :id => pages(:one_design).id
    end

    assert_redirected_to ubiquo_pages_path
  end
end
