# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper.rb"

class FilterHelpersTest < Ubiquo::Filters::UbiquoFilterTestCase

  attr_accessor :params

  def setup
    self.params = { :controller => 'tests', :action => 'index', 'filter_status' => '0' }
    @filter_set = filters_for 'FilterTest' do |f|
      f.boolean :status
    end
    @filters = @filter_set.filters
  end

  test "Should be able to define a filter set" do
    assert_instance_of BooleanFilter, @filters.first
  end

  test "Should be able to render filters" do
    assert_respond_to self, :show_filters
    doc = HTML::Document.new(show_filters).root
    assert_select doc, "div#links_filter_content", 1
  end

  test "Should be able to display filter messages" do
    assert_respond_to self, :show_filter_info
    doc = HTML::Document.new(show_filter_info).root
    assert_select doc, "p[class=search_info]", 1
  end

  test "Shouldn't show filter if collection is empty" do
    @model.delete_all
    @filter_set = filters_for 'FilterTest' do |f|
      f.links :filters, @model.all
    end
    @filters = @filter_set.filters
    doc = HTML::Document.new(show_filters).root
    assert_select doc, "div#links_filter_content", 0    
  end
    
end
