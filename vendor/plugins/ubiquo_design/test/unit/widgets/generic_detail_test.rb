require File.dirname(__FILE__) + '/../../test_helper'

class GenericDetailTest < ActiveSupport::TestCase
  
  test "should create generic_detail" do
    assert_difference 'GenericDetail.count' do
      generic_detail = create_generic_detail
      assert !generic_detail.new_record?, "#{generic_detail.errors.full_messages.to_sentence}"
    end
  end

  test "element method should call first to generic_detail_element" do
    generic_detail = create_generic_detail
    GenericDetail.expects(:generic_detail_element).returns(generic_detail)
    assert_equal generic_detail, generic_detail.element(generic_detail.id)
  end

  test "element method should call to find if generic method not present" do
    generic_detail = create_generic_detail
    assert_equal GenericDetail.first, generic_detail.element(generic_detail.id)
  end

  private
  
  def create_generic_detail(options = {})
    default_options = {
      :name => "Test generic_detail", 
      :block => blocks(:one),
      :model => GenericDetail.to_s,
    }
    GenericDetail.create(default_options.merge(options))
  end
end
