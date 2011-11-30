require File.dirname(__FILE__) + '/../../test_helper'

class Ubiquo::ArticlesControllerTest < ActionController::TestCase

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:articles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end
  
  test "should get show" do
    get :show, :id => articles(:one).id
    assert_response :success
  end

  test "should create article" do
    assert_difference('Article.count') do
      post :create, :article => article_attributes
    end

    assert_redirected_to ubiquo_articles_url
  end

  test "should get edit" do
    get :edit, :id => articles(:one).id
    assert_response :success
  end

  test "should update article" do
    put :update, :id => articles(:one).id, :article => article_attributes
    assert_redirected_to ubiquo_articles_url
  end

  test "should destroy article" do
    assert_difference('Article.count', -1) do
      delete :destroy, :id => articles(:one).id
    end
    assert_redirected_to ubiquo_articles_url
  end
  
  private

  def article_attributes(options = {})
    default_options = {
              :title => 'MyString', # string
              :description => 'MyText', # text
              :published_at => '2011-11-29 10:02:43', # datetime
          }
    default_options.merge(options)  
  end

  def create_article(options = {})
    Article.create(article_attributes(options))
  end
      
end
