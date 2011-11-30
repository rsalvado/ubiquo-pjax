require File.dirname(__FILE__) + '/../../test_helper'

class GenericHighlightedTest < ActiveSupport::TestCase

  test 'should create generic_highglighted' do
    assert_difference 'GenericHighlighted.count' do
      generic_highlighted = create_generic_highlighted
      assert !generic_highlighted.new_record?, "#{generic_highlighted.errors.full_messages.to_sentence}"
    end
  end

  test "elements method should call first to generic_highlighted_elements" do
    generic_highlighted = create_generic_highlighted
    GenericHighlighted.expects(:generic_highlighted_elements).returns(
      GenericHighlighted.scoped(:conditions => {:name => 'non_existing'})
    )
    assert_equal [], generic_highlighted.elements
  end

  test "elements method should call to all if generic method not present" do
    generic_highlighted = create_generic_highlighted
    assert_equal GenericHighlighted.all, generic_highlighted.elements
  end

  private

  def create_generic_highlighted(options = {})
    default_options = {
      :name => "Test generic_highlighted",
      :block => blocks(:one),
      :model => GenericHighlighted.to_s,
      :title => 'Generic highlighted',
      :limit => '5',
    }
    GenericHighlighted.create(default_options.merge(options))
  end
end
