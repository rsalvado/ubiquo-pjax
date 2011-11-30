# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper.rb"

class FilteredSearchTest < ActiveSupport::TestCase

  def setup
    load_test_data
    @m = SearchTestModel
  end

  test "Should be able to define a named_scope and use it" do
    assert_nothing_raised do
      @m.class_eval do
        filtered_search_scopes :enable => [:desc]
        named_scope :desc, lambda { |v| { :conditions => "#{table_name}.description = '#{v}'"} }
      end
    end
    assert_equal [@m.find_by_description('stop')], @m.filtered_search({ 'filter_desc' => 'stop'})
  end

  test "Should not be able to use scopes without enabling them" do
    assert_raise Ubiquo::InvalidFilter do
      @m.class_eval do
        filtered_search_scopes
        named_scope :desc, lambda { |v| { :conditions => "#{table_name}.description = '#{v}'"} }
      end
      @m.filtered_search({'filter_desc' => 'Tired'})
    end
  end

  test "Should be able to use case and accent insensitive search" do
    assert_nothing_raised do
      @m.class_eval do
        filtered_search_scopes
      end
      assert_equal [@m.find_by_title('Tíred')], @m.filtered_search({'filter_text' => 'TIred'})
      assert_equal [@m.find_by_description('òuch réally?')], @m.filtered_search({'filter_text' => 'òuch réally?'})
      assert_equal [@m.find_by_description('bah loot')], @m.filtered_search({'filter_text' => 'niña'})
    end
  end

  test "Should be able to specify fields that should be affected by a text search" do
    @m.class_eval do
      filtered_search_scopes :text => [ :description ]
    end
    assert_equal [@m.find_by_description('bah loot')], @m.filtered_search({'filter_text' => 'loot'})
  end

  test "Should be able to restrict search to only specified scopes" do
    assert_raise Ubiquo::InvalidFilter do
      @m.class_eval do
        filtered_search_scopes
      end
      params = { 'filter_published_start' => Date.yesterday, 'filter_published_end' => (Date.tomorrow + 1), 'filter_text' => 'Tired' }
      @m.filtered_search(params, :scopes => [:text] )
    end
  end

  test "Should be able to use the locale scope" do
    # i18n plugin adds this scope and it should be usable by default.
    assert_nothing_raised do
      @m.class_eval do
        filtered_search_scopes

        named_scope :locale
      end
      @m.filtered_search({"filter_locale" => "es"})
    end
  end

  test 'Should use ubiquo_paginate in paginated_filtered_search' do
    page_param, per_page_param = ['test', 'test']
    @m.expects(:ubiquo_paginate).with(:page => page_param, :per_page => per_page_param)
    @m.paginated_filtered_search(:page => page_param, :per_page => per_page_param) {}
  end

  test "Should use per_page param with paginated_filtered_search" do
    pages, results = @m.paginated_filtered_search(:page => 1, :per_page => 1)
    assert_nil pages[:previous]
    assert_equal 2, pages[:next]
    pages, results = @m.paginated_filtered_search(:page => 3, :per_page => 1)
    assert_nil pages[:next]
    assert_equal 2, pages[:previous]
  end

  test 'Should support order_by when using relation columns' do
    @m.class_eval { cattr_accessor :reflections; @@reflections = {} }
    @m.reflections = { :author => stub(:table_name => 'authors') }
    params = { :order_by => 'articles.author.name', :sort_order => 'desc' }
    options = { :order => 'authors.name desc', :include => 'author' }
    @m.expects(:filtered_search).with(params, options).returns([])
    @m.paginated_filtered_search(params)
  end

  test 'Should support order_by when using relation columns with categories' do
    @m.class_eval { cattr_accessor :reflections; @@reflections = {} }
    @m.reflections = { :section => stub(:table_name => 'categories') }
    params = { :order_by => 'articles.section.name', :sort_order => 'desc' }
    options = { :order => 'categories.name desc', :include => 'sections' }
    @m.expects(:filtered_search).with(params, options).returns([])
    @m.paginated_filtered_search(params)
  end

  test 'Should respect enabled scopes for different models' do
    @m.class_eval do
      filtered_search_scopes :defaults => false
    end
    AlternateSearchTestModel.class_eval do
      filtered_search_scopes
    end
    params = { 'filter_text' => 'Tired' }
    assert_raise Ubiquo::InvalidFilter do
      @m.filtered_search(params)
    end
    assert_nothing_raised do
      AlternateSearchTestModel.filtered_search(params)
    end
  end

  test 'Should not break if filtered_search_scopes has not been called' do
    assert UnfilteredModel.respond_to?(:filtered_search)
    assert_nothing_raised do
      UnfilteredModel.filtered_search
    end
  end

  private

  def self.create_test_tables
    %w{search_test_models alternate_search_test_models unfiltered_models}.each do |table|
      conn = ActiveRecord::Base.connection
      conn.drop_table(table) if conn.tables.include?(table)

      conn.create_table table.to_sym do |t|
        t.string :title
        t.string :description
        t.string :published_at
        t.boolean :private
      end

      model = table.classify
      Object.const_set(model, Class.new(ActiveRecord::Base)) unless Object.const_defined? model
    end
  end

  def load_test_data
    [{ :title => 'Yesterday loot was cool',
       :description => 'òuch réally?',
       :published_at => Date.today,
       :private => true
     },
     { :title => 'Today is the new yesterday. NIÑA',
       :description => 'bah loot',
       :published_at => Date.today,
       :private => false
     },
     { :title => 'Tíred',
       :description => 'stop',
       :published_at => Date.tomorrow,
       :private => false
     }
    ].each { |attrs| SearchTestModel.create(attrs) }
  end

  create_test_tables

end
