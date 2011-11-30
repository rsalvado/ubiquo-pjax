require File.dirname(__FILE__) + '/../../test_helper'

class Ubiquo::CategorySetsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:category_sets)
    assert assigns(:can_manage), 'Category sets should be administrable by default'
  end

  def test_should_not_see_actions_if_not_manageable
    Ubiquo::Config.context(:ubiquo_categories).set(:administrable_category_sets, false)
    get :index
    assert_response :success
    assert !assigns(:can_manage)
  end

  def test_should_not_see_actions_if_set_isnt_editable
    Ubiquo::Config.context(:ubiquo_categories).set(:administrable_category_sets, true)    
    set_attrs = category_set_attributes.merge(:is_editable => false)
    category_set = CategorySet.create(set_attrs)
    get :index
    assert_equal 4, assigns(:category_sets).size
    assert_select "table#category_sets-list tr:nth-child(2)" do
        assert_select "a", 1
    end
    assert_select "table#category_sets-list tr:last-child" do
      assert_select "a", 3
    end
    assert_response :success
  end
  
  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_get_show
    get :show, :id => category_sets(:one).id
    assert_response :success
  end

  def test_should_create_category_set
    assert_difference('CategorySet.count') do
      post :create, :category_set => category_set_attributes
    end

    assert_redirected_to ubiquo_category_sets_url
  end

  def test_should_get_edit
    get :edit, :id => category_sets(:one).id
    assert_response :success
  end

  def test_should_update_category_set
    put :update, :id => category_sets(:one).id, :category_set => category_set_attributes
    assert_redirected_to ubiquo_category_sets_url
  end

  def test_should_destroy_category_set
    assert_difference('CategorySet.count', -1) do
      delete :destroy, :id => category_sets(:one).id
    end
    assert_redirected_to ubiquo_category_sets_url
  end
  
  private

  def category_set_attributes(options = {})
    default_options = {
      :name => 'MyString', # string
      :key => rand.to_s, # string
    }
    default_options.merge(options)  
  end
      
end
