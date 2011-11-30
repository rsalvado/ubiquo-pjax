require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"
require 'mocha'

def create_locale(options = {})
  default_options = {
    :iso_code => 'iso'
  }
  Locale.create(default_options.merge(options))
end

def create_model(options = {})
  TestModel.create(options)
end

def create_related_model(options = {})
  RelatedTestModel.create(options)
end

def create_translatable_related_model(options = {})
  TranslatableRelatedTestModel.create(options)
end

%w{TestModel RelatedTestModel UnsharedRelatedTestModel TranslatableRelatedTestModel ChainTestModelA ChainTestModelB ChainTestModelC OneOneTestModel CallbackTestModel}.each do |c|
  Object.const_set(c, Class.new(ActiveRecord::Base)) unless Object.const_defined? c
end

Object.const_set("InheritanceTestModel", Class.new(ActiveRecord::Base)) unless Object.const_defined? "InheritanceTestModel"

def create_test_model_backend
  # Creates a test table for AR things work properly
  %w{test_models related_test_models unshared_related_test_models translatable_related_test_models chain_test_model_as chain_test_model_bs chain_test_model_cs one_one_test_models inheritance_test_models callback_test_models}.each do |table|
    if ActiveRecord::Base.connection.tables.include?(table)
      ActiveRecord::Base.connection.drop_table table
    end
  end
  ActiveRecord::Base.connection.create_table :test_models, :translatable => true do |t|
    t.string :field1
    t.string :field2
    t.integer :test_model_id
    t.integer :related_test_model_id
  end
  ActiveRecord::Base.connection.create_table :related_test_models do |t|
    t.integer :test_model_id
    t.integer :tracked_test_model_id
    t.string :field1
  end
  ActiveRecord::Base.connection.create_table :unshared_related_test_models do |t|
    t.integer :test_model_id
    t.string :field1
  end
  ActiveRecord::Base.connection.create_table :translatable_related_test_models, :translatable => true do |t|
    t.integer :test_model_id
    t.integer :related_test_model_id
    t.string :field
    t.string :common
    t.integer :lock_version, :default => 0
  end
  ActiveRecord::Base.connection.create_table :chain_test_model_as, :translatable => true do |t|
    t.integer :chain_test_model_b_id
    t.string :field
  end
  ActiveRecord::Base.connection.create_table :chain_test_model_bs, :translatable => true do |t|
    t.integer :chain_test_model_c_id
    t.string :field
  end
  ActiveRecord::Base.connection.create_table :chain_test_model_cs, :translatable => true do |t|
    t.integer :chain_test_model_a_id
    t.string :field
  end
  ActiveRecord::Base.connection.create_table :one_one_test_models, :translatable => true do |t|
    t.integer :one_one_test_model_id
    t.string :independent
    t.string :common
  end
  
  ActiveRecord::Base.connection.create_table :inheritance_test_models, :translatable => true do |t|
    t.integer :translatable_related_test_model_id
    t.integer :related_test_model_id
    t.integer :test_model_id
    t.string :field
    t.string :mixed
    t.string :type
  end
  
  ActiveRecord::Base.connection.create_table :callback_test_models, :translatable => true do |t|
    t.string :field
  end  
  
  # Models used to test extensions
  TestModel.class_eval do
    belongs_to :related_test_model
    named_scope :field1_is_1, {:conditions => {:field1 => '1'}}
    named_scope :field1_is_2, {:conditions => {:field1 => '2'}}
    
    translatable :field1
    has_many :related_test_models
    has_many :unshared_related_test_models
    has_many :shared_related_test_models, :class_name => "RelatedTestModel", :translation_shared => true
    has_many :translatable_related_test_models, :translation_shared => true
    
    has_many :inheritance_test_models, :translation_shared => true, :dependent => :destroy
    has_many :test_models, :dependent => :destroy, :translation_shared => true
    accepts_nested_attributes_for :test_models
    belongs_to :test_model, :translation_shared => true
    
    attr_accessor :abort_on_before_create
    attr_accessor :abort_on_before_update

    def before_create
      !self.abort_on_before_create
    end

    def before_update
      !self.abort_on_before_update
    end     
  end
  
  RelatedTestModel.class_eval do
    belongs_to :test_model
    belongs_to :tracked_test_model, :translation_shared => true, :class_name => 'TestModel'
    
    has_many :inheritance_test_models, :translation_shared => true
    has_many :test_models, :translation_shared => false
  end

  UnsharedRelatedTestModel.class_eval do
    belongs_to :test_model
  end

  TranslatableRelatedTestModel.class_eval do
    translatable :field
    belongs_to :test_model
    belongs_to :related_test_model, :translation_shared => true
    has_many :inheritance_test_models, :translation_shared => true
    has_many :related_test_models
  end
  
  ChainTestModelA.class_eval do
    translatable :field
    belongs_to :chain_test_model_b, :translation_shared => true
    has_many :chain_test_model_cs, :translation_shared => true
  end
  ChainTestModelB.class_eval do
    translatable :field
    belongs_to :chain_test_model_c, :translation_shared => true
    has_many :chain_test_model_as, :translation_shared => true
  end
  ChainTestModelC.class_eval do
    translatable :field, :shared_relations => :chain_test_model_bs
    belongs_to :chain_test_model_a, :translation_shared => true
    has_many :chain_test_model_bs, :translation_shared => true
  end
  
  OneOneTestModel.class_eval do
    translatable :independent
    belongs_to :one_one, :translation_shared => true, :foreign_key => 'one_one_test_model_id', :class_name => 'OneOneTestModel'
    has_one :one_one_test_model, :translation_shared => true
  end
  
  InheritanceTestModel.class_eval do
    translatable :field
    belongs_to :test_model
    belongs_to :related_test_model, :translation_shared => true
    belongs_to :translatable_related_test_model, :translation_shared => true
  end
  
  %w{FirstSubclass SecondSubclass}.each do |c|
    Object.const_set(c, Class.new(InheritanceTestModel)) unless Object.const_defined? c
  end

  SecondSubclass.class_eval do
    translatable :mixed
  end

  Object.const_set('GrandsonClass', Class.new(FirstSubclass)) unless Object.const_defined? 'GrandsonClass'
  
end

  class CallbackTestModel < ActiveRecord::Base
    translatable
    @@after_find_counter = 0
    @@after_initialize_counter = 0      
    
    def self.reset_counter
      @@after_find_counter = 0
      @@after_initialize_counter = 0            
    end
    
    def after_find
      @@after_find_counter = @@after_find_counter + 1
    end

    def after_initialize
      @@after_initialize_counter = @@after_initialize_counter + 1
    end
    
    def self.after_find_counter
      @@after_find_counter
    end

    def self.after_initialize_counter
      @@after_initialize_counter
    end
    
  end

if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end
