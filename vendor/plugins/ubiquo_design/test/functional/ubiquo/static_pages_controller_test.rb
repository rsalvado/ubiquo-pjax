
require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::StaticPagesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  def setup
    login_as
    Ubiquo::Config.context(:ubiquo_design).set(:block_type_for_static_section_widget, :main)
  end

  def test_should_get_index_with_only_static_pages
    get :index
    assert_response :success
    pages = assigns(:static_pages)
    assert_not_nil pages
    assert_equal_set Page.drafts.statics, pages
  end

  def test_should_get_index
    get :index
    assert_response :success
    pages = assigns(:static_pages)
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

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_get_new_with_possible_parent_pages
    get :new
    assert_response :success
    assert_not_equal [], assigns(:static_pages)
    draft_pages_without_home_page = Page.drafts - [pages(:one_design)]
    assert_equal_set draft_pages_without_home_page, assigns(:pages)
  end

  def test_should_get_new_without_possible_parent_pages
    Page.delete_all
    get :new
    assert_response :success
    assert_equal [], assigns(:pages)
  end

  def test_should_create_page_with_blocks_and_static_section_widget
    assert_difference('Page.count') do
      post(:create,
           :page => {
             :name => "Custom page",
             :url_name => "custom_page",
           },
           :static_section => {
             :title => "About Ubiquo",
             :body => "Ubiquo description"
           })
    end
    page = assigns(:static_page)
    assert page
    assert_equal 2, page.blocks.size
    assert_equal "static", page.page_template
    assert_equal ["top", "main"], page.blocks.map(&:block_type)
    assert_equal StaticSection, page.uhook_static_section_widget.class
    assert_equal page.is_the_published?, false

    assert_redirected_to ubiquo_static_pages_path
  end

  def test_should_get_edit
    page = pages(:one)
    page.add_widget(:main, StaticSection.new(:name => "about",
                                             :title => "about ubiquo",
                                             :body => "Description"))
    get :edit, :id => page.id
    assert_response :success
  end

  def test_should_update_page
    page = pages(:one)
    page.add_widget(:main, StaticSection.new(:name => "about",
                                             :title => "about ubiquo",
                                             :body => "Description"))
    put(:update,
        :id => page.id,
        :page => {
          :name => "Custom page",
          :url_name => "custom_page",
        },
        :static_section => {
          :title => "About Ubiquo updated",
          :body => "updated description"
        })
    assert_redirected_to ubiquo_static_pages_path
  end

  def test_should_destroy_page
    # if you remove a draft page, its published page is removed too
    assert_difference('Page.count', -2) do
      delete :destroy, :id => pages(:one_design).id
    end

    assert_redirected_to ubiquo_static_pages_path
  end
end
