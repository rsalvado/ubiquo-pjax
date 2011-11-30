require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'ubiquo/filters/link_filter'

class LinkFilterTest < Ubiquo::Filters::UbiquoFilterTestCase

  def setup
    @filter = LinkFilter.new(@model, @context)
    @filter.configure(:title,@model.all)
  end

  test "Should be able to render a Link filter" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, 'div#links_filter_content a', 3
  end

  test "Should be able to get a message when the filter is set" do
    @context.params.merge!({ 'filter_title' => 'my_title_text' })
    assert_match /my_title_text/, @filter.message.first
  end

end
