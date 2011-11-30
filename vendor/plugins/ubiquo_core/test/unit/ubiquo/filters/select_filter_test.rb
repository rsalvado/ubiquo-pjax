# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'ubiquo/filters/select_filter'

class SelectFilterTest < Ubiquo::Filters::UbiquoFilterTestCase

  def setup
    @filter = SelectFilter.new(@model, @context)
    @filter.configure(:title,@model.all)
  end

  test "Should render a select filter with a small collection" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, 'form', 1
    assert_select doc, 'select[name=filter_title]', 1
  end

  test "Should be able to get a message when the filter is set" do
    @context.params.merge!({ 'filter_title' => 'my_title_text' })
    assert_match /my_title_text/, @filter.message.first
  end

end
