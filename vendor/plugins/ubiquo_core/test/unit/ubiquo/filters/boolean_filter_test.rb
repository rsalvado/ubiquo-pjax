require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'ubiquo/filters/boolean_filter'

class BooleanFilterTest < Ubiquo::Filters::UbiquoFilterTestCase

  def setup
    @filter = BooleanFilter.new(@model, @context)
    @filter.configure(:status,{})
  end

  test "Should be able to render a Boolean filter" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, 'div#links_filter_content a', 2
  end

  test "Should be able to get a message when the filter is set" do
    @context.params.merge!({ 'filter_status' => 0 })
    assert_equal "Status '0'", @filter.message.first
  end

end
