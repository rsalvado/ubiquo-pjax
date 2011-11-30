require File.dirname(__FILE__) + "/../test_helper.rb"

class Ubiquo::ActiveRecordHelpersTest < ActiveSupport::TestCase

  def setup
    Locale.current = nil
  end

  def test_simple_filter
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 1, :locale => 'ca')
    assert_equal 1, TestModel.locale('es').size
    assert_equal 'es', TestModel.locale('es').first.locale
  end
  
  def test_many_contents
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 2, :locale => 'es')
    assert_equal 2, TestModel.locale('es').size
    assert_equal %w{es es}, TestModel.locale('es').map(&:locale)
  end
  
  def test_many_locales_many_contents
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 1, :locale => 'ca')
    create_model(:content_id => 2, :locale => 'es')
    
    assert_equal 2, TestModel.locale('es').size
    assert_equal 1, TestModel.locale('ca').size
    assert_equal 2, TestModel.locale('ca', 'es').size
    assert_equal %w{ca es}, TestModel.locale('ca', 'es').map(&:locale)
  end
  
  def test_search_all_locales_sorted
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 1, :locale => 'ca')
    create_model(:content_id => 2, :locale => 'es')
    create_model(:content_id => 2, :locale => 'en')
    
    assert_equal %w{ca es}, TestModel.locale('ca', :all).map(&:locale)
    assert_equal %w{es en}, TestModel.locale('en', :all).map(&:locale)
    assert_equal %w{es es}, TestModel.locale('es', :all).map(&:locale)
    assert_equal %w{ca en}, TestModel.locale('ca', 'en', :all).map(&:locale)
    
    # :all position is indifferent
    assert_equal %w{es en}, TestModel.locale(:all, 'en').map(&:locale)
  end
  
  def test_search_with_chained_locale_call
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 2, :locale => 'ca')
    create_model(:content_id => 3, :locale => 'en')
    
    assert_equal %w{ca}, TestModel.locale('en','es', :all).locale('es','ca').locale('ca').map(&:locale)
    assert_equal %w{ca}, TestModel.locale('ca').locale('en','es', :all).map(&:locale)
    assert_equal %w{ca}, TestModel.locale('ca').locale(:all).locale(:all).map(&:locale)
    assert_equal %w{}, TestModel.locale('ca').locale(:all).locale('en').map(&:locale)
    assert_equal %w{}, TestModel.locale('es').locale('ca').map(&:locale)
  end

  
  def test_search_by_content
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 1, :locale => 'ca')
    create_model(:content_id => 2, :locale => 'es')
    create_model(:content_id => 2, :locale => 'en')
    
    assert_equal %w{es ca}, TestModel.content(1).all(:order => "id").map(&:locale)
    assert_equal %w{es ca es en}, TestModel.content(1, 2).map(&:locale)
  end
  
  def test_search_by_content_and_locale
    create_model(:content_id => 1, :locale => 'es')
    create_model(:content_id => 1, :locale => 'ca')
    create_model(:content_id => 2, :locale => 'es')
    create_model(:content_id => 2, :locale => 'en')
    
    assert_equal %w{es}, TestModel.locale('es').content(1).map(&:locale)
    assert_equal_set %w{ca en}, TestModel.content(1, 2).locale('ca', 'en').map(&:locale)
    assert_equal_set %w{ca es}, TestModel.content(1, 2).locale('ca', 'es').map(&:locale)
    assert_equal %w{}, TestModel.content(1).locale('en').map(&:locale)
  end
  
  def test_search_by_locale_with_translatable_different_values
    create_model(:content_id => 1, :field1 => '1', :locale => 'es')
    create_model(:content_id => 1, :field1 => '2', :locale => 'en')
    
    assert_equal %w{}, TestModel.locale('es').all(:conditions => {:field1 => '2'}).map(&:locale)
    assert_equal %w{en}, TestModel.locale('es', :all).all(:conditions => {:field1 => '2'}).map(&:locale)
  end
  
  def test_search_by_locale_with_find_scope
    create_model(:content_id => 1, :field1 => '1', :locale => 'es')
    create_model(:content_id => 1, :field1 => '2', :locale => 'en')
    
    assert_equal 1, TestModel.field1_is_1.size
    assert_equal [], TestModel.field1_is_1.locale('en')
    assert_equal 1, TestModel.field1_is_1.locale('es').size
    assert_equal 1, TestModel.field1_is_2.size
    assert_equal [], TestModel.field1_is_2.locale('es')
    assert_equal 1, TestModel.field1_is_2.locale('en').size

    one = TestModel.field1_is_1.locale('en', :all)
    assert_equal 1, one.size
    assert_equal 'es', one.first.locale
    two = TestModel.field1_is_2.locale('es', :all)
    assert_equal 1, two.size
    assert_equal 'en', two.first.locale
  end
  
  def test_search_by_locale_with_include
    model = create_model
    create_related_model(:test_model => model, :field1 => '1')
    create_related_model(:test_model => model, :field1 => '2')
    
    assert_equal [model], TestModel.all(:conditions => "related_test_models.field1 = '1'", :include => :related_test_models)
    assert_equal [], TestModel.locale('es', :all).all(:conditions => "related_test_models.field1 = '10'", :include => :related_test_models)
    assert_equal [model], TestModel.locale('es', :all).all(:conditions => "related_test_models.field1 = '1'", :include => :related_test_models)
  end
  
  def test_search_by_locale_with_joins
    model = create_model
    create_related_model(:test_model => model, :field1 => '1')
    create_related_model(:test_model => model, :field1 => '2')
    
    assert_equal [model], TestModel.all(:conditions => "related_test_models.field1 = '1'", :joins => :related_test_models)
    assert_equal [], TestModel.locale('es', :all).all(:conditions => "related_test_models.field1 = '10'", :joins => :related_test_models)
    assert_equal [model], TestModel.locale('es', :all).all(:conditions => "related_test_models.field1 = '1'", :joins => :related_test_models)
  end
  
  def test_search_by_locale_with_joins_in_another_named_scope
    model = create_model
    TestModel.class_eval do 
      named_scope :scope_for_test, lambda{|id|
        {
          :joins => :related_test_models, 
          :conditions => ["related_test_models.field1 = ?", id.to_s]
        }
      }
    end
    create_related_model(:test_model => model, :field1 => '1')
    create_related_model(:test_model => model, :field1 => '2')
    
    assert_equal [model], TestModel.scope_for_test(1).all
    assert_equal [], TestModel.locale('es', :all).scope_for_test(10).all
    assert_equal [], TestModel.scope_for_test(10).locale('es', :all).all
    assert_equal [model], TestModel.locale('es', :all).scope_for_test(1).all
  end

  def test_search_by_locale_with_custom_sql_joins
    model = create_model
    TestModel.class_eval do
      named_scope :scope_for_test, lambda{|id|
        {
          :joins => 'INNER JOIN related_test_models ON related_test_models.test_model_id = test_models.id',
          :conditions => ["related_test_models.field1 = ?", id.to_s]
        }
      }
    end
    create_related_model(:test_model => model, :field1 => '1')
    create_related_model(:test_model => model, :field1 => '2')

    assert_equal [model], TestModel.scope_for_test(1).all
    assert_equal [], TestModel.locale('es', :all).scope_for_test(10).all
    assert_equal [], TestModel.scope_for_test(10).locale('es', :all).all
    assert_equal [model], TestModel.locale('es', :all).scope_for_test(1).all
  end

  def test_search_by_locale_with_include_in_another_named_scope
    model = create_model
    TestModel.class_eval do
      named_scope :scope_for_test, lambda{|id|
        {
          :include => [:related_test_models],
          :conditions => ["related_test_models.field1 = ?", id.to_s]
        }
      }
    end
    create_related_model(:test_model => model, :field1 => '1')
    create_related_model(:test_model => model, :field1 => '2')

    assert_equal [model], TestModel.scope_for_test(1).all
    assert_equal [], TestModel.locale('es', :all).scope_for_test(10).all
    assert_equal [], TestModel.scope_for_test(10).locale('es', :all).all
    assert_equal [model], TestModel.locale('es', :all).scope_for_test(1).all
  end

  def test_search_by_locale_with_limit
    20.times do 
      create_model(:locale => 'ca', :field1 => '1')
    end
    20.times do 
      create_model(:locale => 'en', :field1 => '2')
    end
    
    assert_equal 40, TestModel.locale('es', :all).count
    assert_equal 10, TestModel.locale('es', :all).all(:conditions => "field1 = '1'", :limit => 10).size
    assert_equal 5, TestModel.locale('en', :all).all(:conditions => "field1 = '1'", :limit => 5).size
  end
  
  def test_search_by_locale_with_group_by
    10.times do 
      create_model(:locale => 'ca', :field1 => '1')
    end
    20.times do 
      create_model(:locale => 'en', :field1 => '2')
    end
    
    assert_equal_set [10, 20], TestModel.locale('es', :all).all(:select => 'COUNT(*) as numvalues', :group => :field1).map(&:numvalues).map(&:to_i)
  end
  
  def test_search_by_locale_without_explicit_find
    model = create_model(:locale => 'ca', :field1 => '1')
    locale_evaled = TestModel.locale('es')
    no_evaled = TestModel.all 
    assert_equal [], locale_evaled
    assert_equal [model], no_evaled
  end
  
  def test_search_by_locale_with_multiple_scope_avaluation
    # if something scoped is passed by reference to a function and is used there,
    # can be effectively avaluated more than once
    create_model(:locale => 'ca', :field1 => '1')
    locale_evaled = TestModel.locale('es')
    locale_evaled.size # first evaluation
    def second_eval to_eval
      assert_equal [], to_eval
    end
    second_eval locale_evaled
  end
  
  def test_search_by_locale_in_model_with_after_find
    CallbackTestModel.create(:field => "hola", :locale => "ca", :content_id => 2)
    CallbackTestModel.reset_counter
    CallbackTestModel.locale('ca', :all).first
    assert_equal 1, CallbackTestModel.after_find_counter
  end
  
  def test_search_by_locale_in_model_with_after_initialize
    CallbackTestModel.create(:field => "hola", :locale => "ca", :content_id => 2)
    CallbackTestModel.reset_counter    
    CallbackTestModel.locale('ca', :all).first
    assert_equal 1, CallbackTestModel.after_initialize_counter
  end  
  
  def test_search_by_locale_with_special_any_locale
    model = create_model(:locale => 'any', :field1 => '1')
    assert_equal [model], TestModel.locale('es')
    assert_equal 1, TestModel.locale('es').count
    assert_equal [model], TestModel.locale(:all)
    assert_equal 1, TestModel.locale(:all).count
  end
  
  def test_search_by_locale_should_work_with_symbols
    model = create_model(:locale => 'es', :field1 => '1')
    assert_equal [model], TestModel.locale(:es)    
    assert_equal 1, TestModel.locale(:es).count
  end

  def test_search_by_locale_in_subclass
    ca = FirstSubclass.create(:locale => 'ca')
    es = ca.translate('es')
    es.save
    assert_equal [ca], FirstSubclass.locale('ca')
    assert_equal 1, FirstSubclass.locale('ca').count
    assert_equal [es], FirstSubclass.locale('es')
    assert_equal 1, FirstSubclass.locale(:all).count
  end

  def test_search_by_locale_in_subclass_doesnt_affect_superclass
    ca = FirstSubclass.create(:locale => 'ca')
    es = ca.translate('es')
    es.save
    FirstSubclass.locale('ca').size #.size to evaluate
    assert_equal_set [ca, es], InheritanceTestModel.all
  end

  def test_search_by_locale_in_different_deep_sti_class_levels
    ca = GrandsonClass.create(:locale => 'ca')
    es = ca.translate('es')
    es.save
    hierarchy = [GrandsonClass, FirstSubclass, InheritanceTestModel]
    (hierarchy + hierarchy.reverse).each do |klass|
      assert_equal [ca], klass.locale('ca')
      assert_equal 1, klass.locale('ca').count
      assert_equal [es], klass.locale('es')
      assert_equal 1, klass.locale(:all).count
    end
  end

  def test_search_by_locale_has_not_paginator_restrictions
    m1 = create_model(:locale => 'ca')
    m2 = create_model(:locale => 'ca')
    TestModel.send(:with_scope, :find => {:limit => 1}) do
      assert_equal_set [m2], TestModel.locale('ca').all(:order => 'id DESC')
    end
  end

  def test_search_translations
    es_m1 = create_model(:content_id => 1, :locale => 'es')
    ca_m1 = create_model(:content_id => 1, :locale => 'ca')
    de_m1 = create_model(:content_id => 1, :locale => 'de')
    es_m2 = create_model(:content_id => 2, :locale => 'es')
    en_m2 = create_model(:content_id => 2, :locale => 'en')
    en_m3 = create_model(:content_id => 3, :locale => 'en')
    
    assert_equal_set [es_m1, de_m1], ca_m1.translations
    assert_equal_set [ca_m1, de_m1], es_m1.translations
    assert_equal_set [en_m2], es_m2.translations
    assert_equal [], en_m3.translations
  end
  
  def test_translations_uses_named_scope
    # this is what is tested
    TestModel.expects(:translations)
    # since we mock translations, the following needs to be mocked too (called on creation)
    TestModel.any_instance.expects(:update_translations)
    create_model(:content_id => 1, :locale => 'es').translations
  end
  
  def test_translations_finds_using_single_translatable_scope
    TestModel.class_eval do
      add_translatable_scope lambda{|el| "test_models.field1 = '#{el.field1}'"}
    end
    
    es_1a = create_model(:content_id => 1, :locale => 'es', :field1 => 'a')
    en_1b = create_model(:content_id => 1, :locale => 'en', :field1 => 'b')
    es_2a = create_model(:content_id => 2, :locale => 'es', :field1 => 'a')
    en_2a = create_model(:content_id => 2, :locale => 'en', :field1 => 'a')
    
    assert_equal_set [], es_1a.translations
    assert_equal_set [], en_1b.translations
    assert_equal_set [en_2a], es_2a.translations
    # restore
    TestModel.instance_variable_set('@translatable_scopes', [])
  end
      
  def test_translations_finds_using_multiple_translatable_scopes
    TestModel.class_eval do
      add_translatable_scope lambda{|el| "test_models.field1 = '#{el.field1}'"}
      add_translatable_scope lambda{|el| "test_models.field2 = '#{el.field2}'"}
    end
    
    es_1a = create_model(:content_id => 1, :locale => 'es', :field1 => 'a', :field2 => 'a')
    en_1b = create_model(:content_id => 1, :locale => 'en', :field1 => 'b', :field2 => 'a')
    es_2a = create_model(:content_id => 2, :locale => 'es', :field1 => 'a', :field2 => 'a')
    en_2a = create_model(:content_id => 2, :locale => 'en', :field1 => 'a', :field2 => 'a')
    ca_2a = create_model(:content_id => 2, :locale => 'ca', :field1 => 'a', :field2 => 'b')
    
    assert_equal_set [], es_1a.translations
    assert_equal_set [], en_1b.translations
    assert_equal_set [en_2a], es_2a.translations
    assert_equal_set [], ca_2a.translations

    # restore
    TestModel.instance_variable_set('@translatable_scopes', [])
  end
  
  def test_should_not_update_translations_if_update_fails
    es_m1 = create_model(:content_id => 1, :locale => 'es', :field2 => 'val')
    ca_m1 = create_model(:content_id => 1, :locale => 'ca', :field2 => 'val')
    assert !es_m1.update_attributes(:field2 => 'newval', :abort_on_before_update => true)
    assert_equal 'val', es_m1.reload.field2
    assert_equal 'val', ca_m1.reload.field2
  end

  def test_should_not_update_translations_if_creation_fails
    es_m1 = create_model(:content_id => 1, :locale => 'es', :field2 => 'val')
    ca_m1 = TestModel.new(:content_id => 1, :locale => 'ca', :field2 => 'newval', :abort_on_before_create => true)
    assert !ca_m1.save
    assert_equal 'val', es_m1.reload.field2
  end

  def test_update_in_another_locale_should_create_correct_instance
    Locale.current = 'es'
    instance = create_model
    assert_equal 'es', instance.locale
  end

  def test_update_in_another_locale_should_update_correct_instance
    ca = create_model(:locale => 'ca', :field2 => 'shared', :field1 => 'uniq_ca')
    Locale.current = 'es'
    assert_difference 'TestModel.count' do
      ca.update_attribute :field1, 'uniq_es'
    end
    es = TestModel.last
    assert_equal 'es', es.locale
    assert_equal 'uniq_ca', ca.reload.field1
    assert_equal 'shared', ca.field2
    assert_equal 'shared', es.field2
    assert_equal 'uniq_es', es.field1
  end

  def test_update_in_another_locale_should_update_correct_existing_instance
    ca = create_model(:locale => 'ca', :field2 => 'shared', :field1 => 'uniq_ca')
    es = ca.translate('es')
    es.save

    Locale.current = 'es'
    assert_no_difference 'TestModel.count' do
      ca.update_attribute :field2, 'new_shared'
    end

    assert_equal 'es', es.locale
    assert_equal 'new_shared', ca.reload.field2
    assert_equal 'new_shared', es.reload.field2
  end

  def test_translate_should_create_translation_with_correct_values_when_copy_all_true_by_default
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = TestModel.translate(1, 'ca')
    assert_nil ca.id
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert_equal 'val', ca.field1
    assert_equal 'val', ca.field2
    assert ca.save
  end

  def test_translate_should_create_translation_with_correct_values_when_copy_all_true_by_default_in_instances
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = es.translate('ca')
    assert_nil ca.id
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert_equal 'val', ca.field1
    assert_equal 'val', ca.field2
    assert ca.save
  end

  def test_translate_should_not_create_translation_when_one_in_the_current_locale_exists
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = es.translate('ca')
    assert_nil ca.id
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert ca.save

    ca_copy = es.translate('ca')
    assert_nil ca_copy.id
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert !ca_copy.save
    assert_nil ca_copy.id

    ca_copy = create_model(:content_id => 1, :locale => 'ca')
    assert_nil ca_copy.id
  end

  def test_translate_should_not_create_translation_when_one_in_the_current_locale_exists_automatically_assigning_locale
    locale = Locale.current
    begin
      Locale.current = 'es'
      es = create_model(:field1 => 'val', :field2 => 'val')
      ca = es.translate('ca')
      assert_nil ca.id
      assert_equal es.content_id, ca.content_id
      assert_equal 'ca', ca.locale
      assert ca.save

      # duplication, abort
      ca_copy = nil
      ca_copy = es.translate('ca')
      assert_nil ca_copy.id
      assert_equal es.content_id, ca.content_id
      assert_equal 'ca', ca.locale

      assert !ca_copy.save

      ca_copy.class.expects(:human_name).twice.returns('FooModelName')
      assert 1, ca_copy.errors.length
      error_message = ca_copy.errors.on(:locale).to_s

      assert error_message.include?("Catalan")
      assert error_message.include?("FooModelName")
      assert_nil ca_copy.id

      # duplication, abort
      # Here we use the same method applied in controllers: Model.create(:content_id => 1)
      Locale.current = 'ca'
      ca_copy = nil
      ca_copy = create_model(:content_id => es.content_id)
      assert_nil ca_copy.id
    ensure
      Locale.current = locale
    end
  end

  def test_translate_should_create_translation_with_correct_values_when_copy_all_false
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = TestModel.translate(1, 'ca', :copy_all => false)
    assert_nil ca.id
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert_nil ca.field1
    assert_equal 'val', ca.field2
    assert ca.save
  end

  def test_translate_should_create_new_instance_when_no_valid_content_id
    create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = TestModel.translate(2, 'ca')
    assert_equal nil, ca.content_id
    assert_equal 'ca', ca.locale
    assert_equal nil, ca.field1
    assert_equal nil, ca.field2
  end

  def test_translate_should_create_new_instance_when_no_content_id
    create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = TestModel.translate(nil, 'ca')
    assert_equal nil, ca.content_id
    assert_equal 'ca', ca.locale
    assert_equal nil, ca.field1
    assert_equal nil, ca.field2
  end
  
  def test_instance_translate_should_create_translation_with_correct_values
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = es.translate('ca', :copy_all => false)
    assert_nil ca.id
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert_nil ca.field1
    assert_equal 'val', ca.field2
    assert ca.new_record?
  end
  
  def test_translate_with_copy_all_should_copy_common_attributes
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    ca = TestModel.translate(1, 'ca', :copy_all => true)
    assert_equal es.content_id, ca.content_id
    assert_equal 'ca', ca.locale
    assert_equal 'val', ca.field1
    assert_equal 'val', ca.field2    
  end
  
  def test_in_locale_instance_method_with_one_locale
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    assert_equal es.id, en.in_locale('es').id
  end
  
  def test_in_locale_instance_method_with_two_locales
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    assert_equal es.id, en.in_locale('es', 'en').id
    assert_equal en.id, en.in_locale('en', 'es').id
    assert_equal en.id, en.in_locale('ca', 'en').id
  end
  
  def test_in_locale_instance_method_with_all_locales
    TestModel.delete_all
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    assert_equal es.id, en.in_locale('es', :all).id
    assert_equal en.id, en.in_locale('en', :all).id
    assert_equal es.id, en.in_locale('ca', 'es', :all).id
  end
  
  def test_destroy_contents
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    ca = create_model(:content_id => 1, :locale => 'ca', :field1 => 'val', :field2 => 'val')
    assert_equal 3, TestModel.count
    es.destroy
    assert_equal 2, TestModel.count
    ca.destroy_content
    assert_equal 0, TestModel.count    
  end
  
  def test_destroy_contents_and_dependants
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    es.inheritance_test_models << InheritanceTestModel.create(:locale => 'es')
    es.inheritance_test_models << InheritanceTestModel.create(:locale => 'es')
    en = es.translate('en')
    en.save
    ca = es.translate('ca')
    ca.save
    assert_equal 3, TestModel.count
    assert_equal 2, InheritanceTestModel.count
    ca.destroy_content
    assert_equal 0, TestModel.count
    assert_equal 0, InheritanceTestModel.count    
  end
  
  def test_destroy_contents_and_dependants_with_itself
    es = create_model(:locale => 'es', :field1 => 'val', :field2 => 'val')
    es.test_models << create_model(:locale => 'es')
    en = es.translate('en')
    en.save
    ca = es.translate('ca')
    ca.save
    assert_equal 4, TestModel.count
    ca.reload.destroy_content # reload to avoid #219
    assert_equal 0, TestModel.count # will fail if using destroy_all (same model)
  end
  
  def test_compare_locales
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    any = create_model(:content_id => 2, :locale => 'any', :field1 => 'val', :field2 => 'val')
    assert es.in_locale?('es')
    assert en.in_locale?('es', 'en')
    assert !en.in_locale?('ca', 'es')
    assert !es.in_locale?('ca')
    assert any.in_locale?('en')
    assert any.in_locale?('jp', 'fr', 'ca', 'es')
    assert any.in_locale?('any')
  end

  def test_compare_locales_without_any
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    any = create_model(:content_id => 2, :locale => 'any', :field1 => 'val', :field2 => 'val')
    assert es.in_locale?('es', :skip_any => true)
    assert en.in_locale?('es', 'en', :skip_any => true)
    assert !en.in_locale?('ca', 'es', :skip_any => true)
    assert !es.in_locale?('ca', :skip_any => true)
    assert !any.in_locale?('en', :skip_any => true)
    assert !any.in_locale?('jp', 'fr', 'ca', 'es', :skip_any => true)
    assert any.in_locale?('any', :skip_any => true)
  end

  def test_compare_locales_with_symbols
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    any = create_model(:content_id => 2, :locale => 'any', :field1 => 'val', :field2 => 'val')
    assert es.in_locale?(:es, :skip_any => true)
    assert en.in_locale?(:es, :en, :skip_any => true)
    assert !en.in_locale?(:ca, :es, :skip_any => true)
    assert !es.in_locale?(:ca, :skip_any => true)
    assert !any.in_locale?(:en, :skip_any => true)
    assert !any.in_locale?(:jp, :fr, :ca, :es, :skip_any => true)
    assert any.in_locale?(:any, :skip_any => true)
  end

  def test_compare_locales_with_locale_object
    es_locale = Locale.create(:iso_code => 'es')
    ca_locale = Locale.create(:iso_code => 'ca')
    es = create_model(:content_id => 1, :locale => 'es', :field1 => 'val', :field2 => 'val')
    en = create_model(:content_id => 1, :locale => 'en', :field1 => 'val', :field2 => 'val')
    assert es.in_locale?(es_locale)
    assert !en.in_locale?(es_locale)
    assert !es.in_locale?(ca_locale)
  end

  def test_named_scopes_work_on_subclasses_if_previously_loaded
    assert_nothing_raised do
      SecondSubclass.scopes.clear
      InheritanceTestModel.class_eval do
        translatable
      end
      SecondSubclass.locale('ca')
    end
  end

end

create_test_model_backend
