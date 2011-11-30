# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Helpers::CoreHelpersTest < ActionView::TestCase

  include Ubiquo::Helpers::CoreUbiquoHelpers

  attr_accessor :params

  def setup
    self.params = { :controller => 'tests', :action => 'index' }
  end

  test "ubiquo_table_headerfy should return a humanized string when receiving a string" do
    assert 'books'.humanize, ubiquo_table_headerfy('books')
  end

  test "ubiquo_table_headerfy should return a proper column header when dealing with a relation" do
    assert_match />secció</, ubiquo_table_headerfy(:"headerfy_section.title")
  end

end

class HeaderfySection

  def self.human_name
    "Secció"
  end

  def self.human_attribute_name(column)
    "títol"
  end

end
