require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'ubiquo/filters/date_filter'

class DateFilterTest < Ubiquo::Filters::UbiquoFilterTestCase

  def setup
    @filter = DateFilter.new(@model, @context)
    @filter.configure
  end

  test "Should be able to render a date filter" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, "input[id=filter_filter_publish_start]", 1
    assert_select doc, "input[id=filter_filter_publish_end]", 1
  end

  test "Should be able to get a message when date filter is set" do
    params = {
      "filter_publish_start" => "3/12/2009",
      "filter_publish_end"   => "1/10/2010"
    }
    @context.params.merge!(params)
    assert_match /3\/12\/2009/, @filter.message.first
    assert_match /1\/10\/2010/, @filter.message.first
  end

end
