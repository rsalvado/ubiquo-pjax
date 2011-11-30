require File.dirname(__FILE__) + "/../test_helper.rb"

class Ubiquo::SharedRelationsTest < ActiveSupport::TestCase

  # In these tests names, "simple" involves a non-translatable model, else "translatable" is used

  def setup
    Locale.current = nil
  end

  def test_copy_shared_relations_simple_has_many_case
    TestModel.share_translations_for :unshared_related_test_models
    test_model = create_model(:locale => 'ca')
    test_model.unshared_related_test_models << UnsharedRelatedTestModel.create

    # not supported, should fail
    assert_raise RuntimeError do
      test_model.translate('en')
    end

    # check no changes
    assert_equal 1, TestModel.count
    assert_equal 1, UnsharedRelatedTestModel.count
    TestModel.reflections[:unshared_related_test_models].instance_variable_set('@options', {})
  end

  def test_copy_shared_relations_simple_belongs_to_case
    rel = TranslatableRelatedTestModel.create :locale => 'ca'
    rel.related_test_model = create_related_model
    rel.save

    translated = rel.translate('en')
    assert_equal rel.related_test_model, translated.related_test_model

    # check no extra instances created
    assert_equal 1, RelatedTestModel.count
    assert_equal 1, TranslatableRelatedTestModel.count
  end

  def test_copy_shared_relations_simple_belongs_to_case_using_id
    rel = TranslatableRelatedTestModel.create :locale => 'ca'

    translated = rel.translate('en')
    translated.save

    rel.related_test_model_id = create_related_model.id
    rel.save
    assert_equal rel.related_test_model, translated.reload.related_test_model
  end

  def test_copy_shared_relations_simple_belongs_update_case
    rel = TranslatableRelatedTestModel.create :locale => 'ca'
    rel.related_test_model = create_related_model
    rel.save

    translated = rel.translate('en')
    translated.save

    new_end = create_related_model
    translated.related_test_model = new_end
    translated.save
    assert_equal new_end.id, translated.reload.related_test_model.id
    assert_equal translated.related_test_model, rel.reload.related_test_model
  end

  def test_should_not_copy_relations_as_default_simple_has_many_creation_case
    m1 = create_model(:locale => 'ca')
    m1.unshared_related_test_models << UnsharedRelatedTestModel.create(:field1 => '1')
    m1.unshared_related_test_models << UnsharedRelatedTestModel.create(:field1 => '2')
    m2 = m1.translate('en')

    assert_equal 0, m2.unshared_related_test_models.size
    assert_equal 2, UnsharedRelatedTestModel.count
  end

  def test_should_not_copy_relations_as_default_simple_has_many_update_case_as_default
    m1 = create_model(:locale => 'ca')
    m1.unshared_related_test_models << UnsharedRelatedTestModel.create(:field1 => '1')
    m1.unshared_related_test_models << UnsharedRelatedTestModel.create(:field1 => '2')
    m2 = m1.translate('en')
    m1.unshared_related_test_models = [UnsharedRelatedTestModel.create(:field1 => '3')]

    assert_equal 0, m2.unshared_related_test_models.size
    assert_equal 3, UnsharedRelatedTestModel.count
  end

  def test_should_copy_shared_relations_translatable_has_many_creation_case
    m1 = create_model(:locale => 'ca')
    m1.translatable_related_test_models << create_translatable_related_model(:common => '1', :locale => 'ca')
    m1.translatable_related_test_models << create_translatable_related_model(:common => '2', :locale => 'ca')
    m2 = m1.translate('en')

    assert_equal 2, m2.translatable_related_test_models.size # as m1
    assert_equal %w{ca ca}, m2.translatable_related_test_models.map(&:locale)
    assert_equal m1.translatable_related_test_models.first.content_id, m2.translatable_related_test_models.first.content_id
    assert_equal m1.translatable_related_test_models, m2.translatable_related_test_models
    assert_equal 2, TranslatableRelatedTestModel.count
    assert_equal 1, TranslatableRelatedTestModel.count(:conditions => {:common => '1'})
    assert_equal 1, TranslatableRelatedTestModel.count(:conditions => {:common => '2'})
  end

  def test_should_copy_shared_relations_translatable_has_many_update_case
    m1 = create_model(:locale => 'ca')
    m1.translatable_related_test_models << create_translatable_related_model(:common => '1', :locale => 'ca')
    m1.translatable_related_test_models << create_translatable_related_model(:common => '2', :locale => 'ca')
    m2 = m1.translate('en')
    m2.save
    m1.translatable_related_test_models = [create_translatable_related_model(:common => '3', :locale => 'ca')]

    assert_equal 1, m2.reload.translatable_related_test_models.size # as m1
    assert_equal %w{ca}, m2.translatable_related_test_models.map(&:locale)
    assert_equal_set m1.translatable_related_test_models.map(&:content_id), m2.translatable_related_test_models.map(&:content_id)
    assert_equal 3, TranslatableRelatedTestModel.count # 3 original
    assert_equal 1, TranslatableRelatedTestModel.count(:conditions => {:common => '3'})
  end

  def test_should_copy_shared_relations_translatable_chained_creation_case
    a = ChainTestModelA.create(:locale => 'ca', :content_id => 10)
    a.chain_test_model_b = (b = ChainTestModelB.create(:locale => 'ca', :content_id => 20))
    b.chain_test_model_c = (c = ChainTestModelC.create(:locale => 'ca', :content_id => 30))
    c.chain_test_model_a = a
    a.save; b.save; c.save;
    assert_equal a, a.chain_test_model_b.chain_test_model_c.chain_test_model_a

    newa = a.translate('en')
    assert_equal b.content_id, newa.chain_test_model_b.content_id
    assert_equal c.content_id, newa.chain_test_model_b.chain_test_model_c.content_id
    assert_equal 'ca', newa.chain_test_model_b.locale
    assert_equal 'ca', newa.chain_test_model_b.chain_test_model_c.locale
    assert_equal a, a.chain_test_model_b.chain_test_model_c.chain_test_model_a

    # newa is not saved, should not be found
    assert_equal a, newa.chain_test_model_b.chain_test_model_c.chain_test_model_a

    newa.save
    assert_equal a.content_id, newa.chain_test_model_b.chain_test_model_c.chain_test_model_a.content_id
  end

  def test_should_copy_shared_relations_translatable_has_one_creation_case
    m1 = OneOneTestModel.create(:locale => 'ca', :common => '2')
    m1.one_one = OneOneTestModel.create(:common => '1', :locale => 'ca')
    m1.save
    m2 = m1.translate('en')

    assert_not_nil m2.one_one
    assert_not_nil m1.reload.one_one
    assert_equal m1.one_one, m2.one_one
    assert_equal 'ca', m2.one_one.locale
    assert_equal 2, OneOneTestModel.count
    assert_equal 1, OneOneTestModel.count(:conditions => {:common => '1'})
    assert_equal 1, OneOneTestModel.count(:conditions => {:common => '2'})
  end

  def test_should_copy_shared_relations_translatable_has_one_update_case
    ca = OneOneTestModel.create(:locale => 'ca', :independent => 'ca')
    ca.one_one = OneOneTestModel.create(:independent => 'subca', :locale => 'ca')
    ca.save
    en = ca.translate('en')
    en.independent = 'en'
    en.one_one.update_attribute :independent, 'suben'
    en.save
    es = en.reload.translate('es')
    es.independent = 'es'
    es.one_one.update_attribute :independent, 'subes'
    es.save
    es.save
    assert_equal 4, OneOneTestModel.count

    assert_equal 'en', en.reload.independent
    assert_equal 'subes', en.one_one.independent
    assert_equal 'es', es.reload.independent
    assert_equal 'subes', es.one_one.independent
  end

  def test_copy_shared_relations_translatable_belongs_to_creation_case
    original = create_model(:locale => 'ca')
    original.test_model = original_relation = create_model(:locale => 'ca')
    original.save

    translated = original.translate('en')
    translated.save

    assert translated.test_model, 'translated instance relation is empty'
    assert_equal original.locale, translated.test_model.locale
    assert_equal original_relation, translated.test_model
    assert_equal 3, TestModel.count
    assert_equal(
      original.id + 2,
      [translated.test_model.id, translated.id].max,
      'instances were created and deleted'
    )
  end

  def test_copy_shared_relations_translatable_belongs_to_update_case
    original = create_model(:locale => 'ca')
    original_relation = create_model(:locale => 'ca')
    original.test_model = original_relation
    original.save

    translated = original.translate('en')
    translated.save

    updated_relation = create_model(:locale => 'en')
    translated.test_model = updated_relation
    translated.save

    assert_not_equal original_relation, original.reload.test_model
    assert_equal updated_relation, original.test_model
    assert_equal 4, TestModel.count
    assert_equal(
      original.id + 3,
      [original.test_model.id, original.id].max,
      'instances were created and deleted'
    )
  end

  def test_copy_shared_relations_translatable_belongs_to_update_case_translation_existing
    original = create_model(:locale => 'ca')
    original_relation = create_model(:locale => 'ca')
    original.test_model = original_relation
    original.save

    translated = original.translate('en')
    translated.save

    updated_relation = create_model(:locale => 'en')
    ca_updated_relation = updated_relation.translate('ca')
    ca_updated_relation.save

    translated.test_model = updated_relation
    translated.save

    assert_not_equal original_relation, original.reload.test_model
    assert_equal ca_updated_relation, original.reload.test_model
  end

  def test_has_many_with_common_belongs_to_for_different_translations_and_dependent_destroy_with_explicit_locale
    TestModel.delete_all
    ca_parent = create_model(:locale => 'ca')
    ca_parent.test_models << child_ca = create_model(:locale => 'ca')
    child_en = child_ca.translate('en')
    child_en.save
    ca_parent.test_models << child_en
    ca_parent.reload

    en_parent = ca_parent.translate('en')
    Locale.current = 'en'
    en_parent.save
    assert_equal 'en', Locale.current, 'Locale.current should maintain its value'
    Locale.current = nil

    assert_equal [child_en], en_parent.reload.test_models
    assert_equal [child_ca], ca_parent.reload.test_models
    assert_equal 4, TestModel.count
  end

  def test_should_get_translated_has_many_elements_from_a_non_translated_model
    non_translated = RelatedTestModel.create

    translated_1, translated_2 = [
      TestModel.create(:content_id => 1, :locale => 'en', :related_test_model => non_translated),
      TestModel.create(:content_id => 1, :locale => 'es', :related_test_model => non_translated)
    ]

    assert non_translated.valid?
    assert translated_1.valid?
    assert translated_2.valid?

    assert_equal [translated_1, translated_2], non_translated.test_models
    assert_equal [translated_1], non_translated.test_models.locale('en')
    assert_equal [translated_2], non_translated.test_models.locale('es')
  end

  def test_should_get_translated_has_many_elements_from_a_non_translated_model_using_default_locale
    non_translated = RelatedTestModel.create

    translated_1, translated_2 = [
      InheritanceTestModel.create(:content_id => 1, :locale => 'en', :related_test_model => non_translated),
      InheritanceTestModel.create(:content_id => 1, :locale => 'es', :related_test_model => non_translated)
    ]

    Locale.current = 'en'
    assert_equal [translated_1], non_translated.inheritance_test_models
    Locale.current = 'es'
    assert_equal [translated_2], non_translated.inheritance_test_models
  end

  def test_should_get_translated_belongs_to_from_a_non_translated_model_using_default_locale
    translated_en = TestModel.create(:locale => 'en')
    translated_ca = translated_en.translate('ca')
    translated_ca.save
    non_translated = RelatedTestModel.create(:tracked_test_model_id => translated_en.id)

    Locale.current = 'en'
    assert_equal translated_en, non_translated.tracked_test_model
    Locale.current = 'ca'
    assert_equal translated_ca, non_translated.tracked_test_model
    Locale.current = 'es'
    assert [translated_ca, translated_en].include?(non_translated.tracked_test_model)
  end

  def test_has_many_to_translated_sti
    InheritanceTestModel.destroy_all

    test_model = RelatedTestModel.create
    first_inherited = FirstSubclass.create(:field => "Hi", :locale => "en", :related_test_model => test_model)

    assert_equal 1, test_model.inheritance_test_models.size

    second_inherited = first_inherited.translate
    second_inherited.field = "Hola"
    second_inherited.locale = 'es'

    second_inherited.save

    assert_equal 2, test_model.reload.inheritance_test_models.size
    assert_equal "Hi", test_model.inheritance_test_models.locale("en").first.field
    assert_equal "Hola", test_model.inheritance_test_models.locale("es").first.field
    assert_equal "Hi", test_model.inheritance_test_models.locale("en", 'es').first.field
    assert_equal "Hola", test_model.inheritance_test_models.locale("es", 'en').first.field
  end

  def test_translatable_has_many_to_translated_sti_correctly_updates_the_associations
    origin = TranslatableRelatedTestModel.create(:locale => 'en')
    translated_origin = origin.translate('es')
    translated_origin.save

    sti_instance = FirstSubclass.create(:locale => "en", :translatable_related_test_model => origin)

    assert_equal 1, origin.reload.inheritance_test_models.size

    translated_sti = sti_instance.translate('es', :copy_all => true)
    translated_sti.save

    assert_equal 1, origin.reload.inheritance_test_models.size
    assert_equal 1, translated_origin.reload.inheritance_test_models.size

    translated_origin.inheritance_test_models = []
    assert_equal [], origin.reload.inheritance_test_models

    translated_origin.inheritance_test_models = [translated_sti]
    assert_equal [sti_instance], origin.reload.inheritance_test_models

  end

  def test_non_translatable_has_many_to_translated_sti_correctly_updates_the_associations
    origin = RelatedTestModel.create

    sti_instance = FirstSubclass.create(:locale => "en", :related_test_model => origin)

    assert_equal 1, origin.reload.inheritance_test_models.count

    translated_sti = sti_instance.translate('es', :copy_all => true)
    translated_sti.save

    assert_equal 2, origin.reload.inheritance_test_models.count

    origin.inheritance_test_models = []
    assert_equal [], origin.reload.inheritance_test_models
  end

  def test_translatable_belongs_to_correctly_updates_translations_when_nullified_by_attribute_assignation
    origin, translated_origin = create_test_model_with_relation_and_translation

    assert_equal origin.test_model, translated_origin.test_model
    assert_kind_of TestModel, origin.test_model

    origin.test_model_id = nil
    origin.save
    assert_nil origin.test_model_id
    assert_nil origin.reload.test_model
    assert_nil translated_origin.reload.test_model
  end

  def test_translatable_belongs_to_correctly_updates_translations_when_nullified_by_association
    origin, translated_origin = create_test_model_with_relation_and_translation

    origin.test_model = nil
    origin.save
    assert_nil origin.test_model
    assert_nil origin.test_model_id
    assert_nil translated_origin.reload.test_model
  end

  def test_translatable_belongs_to_correctly_updates_translations_when_nullified_by_attribute_update
    origin, translated_origin = create_test_model_with_relation_and_translation
    parent = TestModel.find(origin.test_model.id)

    origin.update_attribute :test_model_id, nil
    assert_nil origin.reload.test_model
    assert_nil translated_origin.reload.test_model

    # now revert and try update_attributes, which is slightly different...
    origin.update_attribute :test_model_id, parent.id
    assert_equal parent, origin.test_model
    origin.update_attributes :test_model_id => nil
    assert_nil origin.test_model
    assert_nil translated_origin.reload.test_model
  end

  def test_translatable_belongs_to_correctly_updates_translations_when_nullified_when_fresh
    origin, translated_origin = create_test_model_with_relation_and_translation
    assert_not_nil origin.test_model

    origin.reload.update_attribute :test_model_id, nil
    assert_nil origin.reload.test_model
    assert_nil translated_origin.reload.test_model
  end

  def test_should_not_redo_translations_in_has_many_translate_with_copy_all
    ca = TestModel.create(:locale => 'ca')
    ca.test_models << TestModel.create(:locale => 'ca')
    original_id = ca.test_models.first.id
    ca.translate('en', :copy_all => true)
    ca.reload
    assert_equal original_id, ca.test_models.first.id
  end

  def test_should_return_correct_count_in_shared_translations
    ca = TestModel.create(:locale => 'ca')
    ca.test_models << TestModel.create(:locale => 'ca')
    assert_equal 1, ca.test_models.count

    en = ca.translate('en')
    en.save
    assert_equal 1, ca.test_models.count
  end

  def test_should_accept_relations_from_other_locales
    ca = TestModel.create(:locale => 'ca')
    ca.test_models << TestModel.create(:locale => 'ca')
    en = ca.translate('en')
    en.save
    ca.test_models << TestModel.create(:locale => 'en')

    assert_equal 2, ca.test_models.count
    assert_equal 2, en.reload.test_models.count

    en_relation = ca.test_models.last.translate('en')
    en_relation.save

    assert_equal 2, ca.test_models.count
    assert_equal 2, en.test_models.count
  end

  def test_should_return_correct_relations_from_other_locales
    ca = TestModel.create(:locale => 'ca')
    ca.test_models << (ca_relation = TestModel.create(:locale => 'ca'))
    en = ca.translate('en')
    en.save
    ca.test_models << TestModel.create(:locale => 'en')

    assert_equal_set ['ca', 'en'], ca.test_models.map(&:locale)
    assert_equal_set ['ca', 'en'], en.reload.test_models.map(&:locale)

    en_relation = ca_relation.translate('en')
    en_relation.save

    assert_equal_set ['ca', 'en'], ca.test_models.map(&:locale).uniq
    assert_equal ['en'], en.test_models.map(&:locale).uniq
  end

  def test_should_return_correct_relations_from_other_locales_belongs_to_case
    ca = TestModel.create(:locale => 'ca')
    ca.test_model = parent = TestModel.create(:locale => 'ca')
    ca.save

    en = ca.translate('en')
    en.save

    parent_en = parent.translate('en')
    parent_en.save

    assert_equal parent, ca.test_model
    assert_equal parent_en, en.test_model
  end

  def test_share_translations_for
    assert !TestModel.reflections[:unshared_related_test_models].options[:translation_shared]

    TestModel.class_eval do
      share_translations_for :unshared_related_test_models
    end
    assert TestModel.reflections[:unshared_related_test_models].options[:translation_shared]

    TestModel.reflections[:unshared_related_test_models].instance_variable_set('@options', {})
  end

  def test_share_translations_for_multiple_times_does_not_crash
    assert !TestModel.reflections[:unshared_related_test_models].options[:translation_shared]

    TestModel.class_eval do
      share_translations_for :unshared_related_test_models, :unshared_related_test_models
    end

    TestModel.reflections[:unshared_related_test_models].instance_variable_set('@options', {})
  end

  def test_share_translations_for_translation_shared_belongs_to_untranslated
    en = InheritanceTestModel.create(:locale => 'en')
    en.related_test_model = RelatedTestModel.create
    ca = en.translate('ca')
    assert ca.related_test_model
  end

  def test_semi_translated_content_in_a_has_many_avoids_repeated
    en = TestModel.create(:locale => 'en')
    en.test_model = main = TestModel.create(:locale => 'en')
    ca = en.translate('ca')
    ca.save
    assert_equal ca.test_model, en.test_model
    assert_equal 1, main.test_models.size
    assert_equal 'en', main.test_models.first.locale
  end

  def test_nested_attributes_situation_with_multiple_nil_content_id
    en = TestModel.create
    en.test_models_attributes = [{}, {}]
    assert_equal 2, en.test_models.count
  end

  def test_current_locale_should_have_preference_when_loading_relations
    en = TestModel.create(:locale => 'en')
    en.test_model = main = TestModel.create(:locale => 'en')
    ca = en.translate('ca')
    ca.save
    Locale.current = 'ca'
    assert_equal 'ca', main.test_models.first.locale
  end

  def test_share_translations_for_translation_shared_has_one
    en = OneOneTestModel.create(:locale => 'en')
    en.one_one_test_model = OneOneTestModel.create(:locale => 'en')
    ca = en.translate('ca')
    ca.save
    assert ca.reload.one_one_test_model
    assert_equal ca.one_one_test_model, en.reload.one_one_test_model
  end

  def test_translation_shared_associations_should_have_correct_finder_sql
    en = TestModel.create(:locale => 'en')
    related1 = TestModel.create(:locale => 'en', :field1 => 'related1')
    related2 = TestModel.create(:locale => 'en', :field1 => 'related2')
    en.test_models << related1
    en.test_models << related2
    ca = en.translate 'ca'
    assert ca.test_models.first(:conditions => {:locale => 'en'})
    assert_nil ca.test_models.first(:conditions => {:locale => 'ca'})
    assert_equal related1, ca.test_models.first(:conditions => { :locale => 'en', :field1 => 'related1' })
    assert_equal related2, ca.test_models.first(:conditions => { :locale => 'en', :field1 => 'related2' })
  end

  def test_translation_shared_associations_should_warn_in_count_with_args
    en = TestModel.create(:locale => 'en')
    en.test_models << TestModel.create(:locale => 'en')
    ca = en.translate 'ca'
    assert_raise NotImplementedError do
      ca.test_models.count(:conditions => {:locale => 'en'})
    end
  end

  private

  def create_test_model_with_relation_and_translation
    origin = TestModel.create(:locale => 'en')
    origin.test_model = TestModel.create(:locale => 'en')
    origin.save
    translated_origin = origin.translate('es')
    translated_origin.save
    [origin, translated_origin]
  end

end

create_test_model_backend
