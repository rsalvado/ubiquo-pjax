# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'ubiquo/filters/links_or_select_filter'

class LinksOrSelectFilterTest < Ubiquo::Filters::UbiquoFilterTestCase

  def setup
    @filter = LinksOrSelectFilter.new(@model, @context)
    @filter.configure(:title,@model.all)
  end

  test "Should render a link filter with a small collection" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, 'div#links_filter_content a', 3
  end

  test "Should render a select filter with a bigger collection" do
    load_more_test_data
    @filter.configure(:title, @model.all)
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, 'form', 1
    assert_select doc, 'select[name=filter_title]', 1
  end

  test "Should be able to get a message when the filter is set" do
    @context.params.merge!({ 'filter_title' => 'my_title_text' })
    assert_match /my_title_text/, @filter.message.first
  end

  private

  def load_more_test_data
    [
     { :title => 'Yesterday loot was cool',
       :description => 'òuch réally?',
       :published_at => Date.today,
       :status => true
     },
     { :title => 'Today is the new yesterday. NIÑA',
       :description => 'bah loot',
       :published_at => Date.today,
       :status => false
     },
     { :title => 'Tíred',
       :description => 'stop',
       :published_at => Date.tomorrow,
       :status => false
     }
    ].each { |attrs| @model.create(attrs) }
  end

end
