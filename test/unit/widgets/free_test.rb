require File.dirname(__FILE__) + '/../../test_helper'

class FreeTest < ActiveSupport::TestCase

  test "should create free" do
    assert_difference 'Free.count' do
      free = create_free
      assert !free.new_record?, "#{free.errors.full_messages.to_sentence}"
    end
  end

  test "should require content" do
    assert_no_difference 'Free.count' do
      free = create_free(:content => nil)
      assert free.errors.on(:content)
    end
  end

  private

  def create_free(options = {})
    default_options = {
      :name => "Test free",
      :content => 'Content example',
      :block => blocks(:one)
    }
    Free.create(default_options.merge(options))
  end
end
