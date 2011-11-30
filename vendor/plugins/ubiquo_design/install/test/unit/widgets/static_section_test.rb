require File.dirname(__FILE__) + '/../../test_helper'

class StaticSectionTest < ActiveSupport::TestCase

  def test_should_create_static_section
    assert_difference 'StaticSection.count' do
      static_section = create_static_section
      assert !static_section.new_record?, "#{static_section.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_title
    assert_no_difference 'StaticSection.count' do
      static_section = create_static_section(:title => '')
      assert static_section.errors.on(:title)
    end
  end

  private

  def create_static_section(options = {})
    default_options = {
      :name => "Test static_section",
      :title => 'Static section title',
      :block => blocks(:one),
      # Insert other options for widget here
    }
    StaticSection.create(default_options.merge(options))
  end
end
