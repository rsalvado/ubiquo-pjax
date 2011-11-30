require File.dirname(__FILE__) + '/../../test_helper'

class Ubiquo::CategoriesControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  def setup
    session[:locale] = "en_US"
  end
  
  def test_should_get_index
    get :index, :category_set_id => category_sets(:one).id
    assert_response :success
    assert_not_nil assigns(:categories)
  end

  def test_index_should_be_filtered_by_category_set
    Category.delete_all
    category_sets(:one).categories << 'One'
    category_sets(:two).categories << 'Two'
    get :index, :category_set_id => category_sets(:one).id
    assert assigns(:categories).map(&:name).include?('One')
    assert !assigns(:categories).map(&:name).include?('Two')
  end

  def test_should_get_new
    get :new, :category_set_id => category_sets(:one).id
    assert_response :success
  end
  
  def test_should_get_show
    get :show, :id => categories(:one).id, :category_set_id => category_sets(:one).id
    assert_response :success
  end

  def test_should_create_category
    assert_difference('Category.count') do
      post :create, :category => category_attributes, :category_set_id => category_sets(:one).id
    end

    assert_redirected_to ubiquo_category_set_categories_url
  end

  def test_should_create_category_from_current_category_set
    category_set = category_sets(:one)
    post :create, :category => category_attributes, :category_set_id => category_set.id

    assert_equal category_set, Category.last.category_set
  end

  def test_should_get_edit
    get :edit, :id => categories(:one).id, :category_set_id => category_sets(:one).id
    assert_response :success
  end

  def test_edit_should_redirect_to_correct_locale
    get :edit, :id => categories(:one).id, :category_set_id => category_sets(:one).id, :locale => 'jp'
    if Ubiquo::Config.context(:ubiquo_categories).get(:connector).to_sym == :i18n
      assert_redirected_to ubiquo_category_set_categories_url
    else
      assert_response :success
    end
  end

  def test_should_update_category
    put :update, :id => categories(:one).id, :category => category_attributes, :category_set_id => category_sets(:one).id
    assert_redirected_to ubiquo_category_set_categories_url
  end

  def test_should_destroy_category
    assert_difference('Category.count', -1) do
      delete :destroy, :id => categories(:one).id, :category_set_id => category_sets(:one).id
    end
    assert_redirected_to ubiquo_category_set_categories_url
  end
  
  private

  def category_attributes(options = {})
    default_options = {
              :name => 'MyString', # string
              :description => 'MyText', # text
          }
    default_options.merge(options)  
  end

  def create_category(options = {})
    Category.create(category_attributes(options))
  end
      
end
