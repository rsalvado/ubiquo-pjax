require File.dirname(__FILE__) + '/../../test_helper'

class Ubiquo::<%= controller_class_name %>ControllerTest < ActionController::TestCase

  <%- if options[:translatable] -%>
  def setup
    session[:locale] = "en_US"
  end
  
  <%- end -%>
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:<%= table_name %>)
  end

  test "should get new" do
    get :new
    assert_response :success
  end
  
  test "should get show" do
    get :show, :id => <%= table_name %>(:one).id
    assert_response :success
  end

  test "should create <%= file_name %>" do
    assert_difference('<%= class_name %>.count') do
      post :create, :<%= file_name %> => <%= file_name %>_attributes
    end

    assert_redirected_to ubiquo_<%= table_name %>_url
  end

  test "should get edit" do
    get :edit, :id => <%= table_name %>(:one).id
    assert_response :success
  end

  <%- if options[:translatable] -%>
  test "should redirect to correct locale" do
    get :edit, :id => <%= table_name %>(:one).id, :locale => 'other'
    assert_redirected_to ubiquo_<%= table_name %>_url
  end

  <%- end -%>
  test "should update <%= file_name %>" do
    put :update, :id => <%= table_name %>(:one).id, :<%= file_name %> => <%= file_name %>_attributes
    assert_redirected_to ubiquo_<%= table_name %>_url
  end

  test "should destroy <%= file_name %>" do
    assert_difference('<%= class_name %>.count', -1) do
      delete :destroy, :id => <%= table_name %>(:one).id
    end
    assert_redirected_to ubiquo_<%= table_name %>_url
  end
  
  private

  def <%= file_name %>_attributes(options = {})
    default_options = {
      <% for attribute in attributes -%>
        :<%= attribute.name %> => '<%= attribute.default %>', # <%= attribute.type.to_s %>
      <% end -%>
    }
    default_options.merge(options)  
  end

  def create_<%= file_name %>(options = {})
    <%= name.classify %>.create(<%= file_name %>_attributes(options))
  end
      
end
