require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoCategories::Connectors::I18nTest < ActiveSupport::TestCase

  if Ubiquo::Plugin.registered[:ubiquo_i18n]

    I18n = UbiquoCategories::Connectors::I18n

    def setup
      save_current_connector(:ubiquo_categories)
      I18n.load!
    end

    def teardown
      reload_old_connector(:ubiquo_categories)
      Locale.current = nil
    end

    test 'Category should be translatable' do
      assert Category.is_translatable?
    end

    test 'uhook_create_categories_table_should_create_table_with_i18n_info' do
      ActiveRecord::Migration.expects(:create_table).with(:categories, :translatable => true)
      ActiveRecord::Migration.uhook_create_categories_table {}
    end

    test 'uhook_create_category_relations_table_should_create_table' do
      ActiveRecord::Migration.expects(:create_table).with(:category_relations)
      ActiveRecord::Migration.uhook_create_category_relations_table {}
    end

    test 'uhook_assign_to_set should add to set' do
      set = create_category_set
      set.categories.expects('<<').with{|category| category.to_s == 'category'}
      CategorySet.uhook_assign_to_set set, ['category'], set
    end

    test 'uhook_categorized_with should assign translation shared' do
      categorize :cities
      CategorySet.uhook_categorized_with :cities, {}
      assert CategoryTranslatableTestModel.reflections[:cities].options[:translation_shared]
    end

    test 'uhook_category_identifier_for_name should return content_id' do
      set = create_category_set
      set.categories << 'category'
      assert_equal(
        set.categories.first.content_id,
        set.uhook_category_identifier_for_name(set.categories.first.name)
      )
    end

    test 'uhook_select_fittest should return the same category if no locale' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      assert_equal set.categories.first, set.uhook_select_fittest(set.categories.first)
    end

    test 'uhook_select_fittest should return the same category if same locale' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      assert_equal set.categories.first, set.uhook_select_fittest(set.categories.first, :locale => 'ca')
    end

    test 'uhook_select_fittest should return the available category if no correct locale' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      assert_equal set.categories.first, set.uhook_select_fittest(set.categories.first, :locale => 'jp')
    end

    test 'uhook_select_fittest should return in correct locale' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      catalan_category = set.categories.first
      translation = catalan_category.translate('jp', :copy_all => true)
      translation.save
      assert_equal translation, set.uhook_select_fittest(catalan_category, :locale => 'jp')
    end

    test 'uhook_category_identifier_condition should return a content_id condition' do
      assert_equal(
        ["#{Category.alias_for_association('cities')}.content_id IN (?)", [1]],
        Category.uhook_category_identifier_condition([1], :cities)
      )
    end

    test 'uhook_join_category_table_in_category_conditions_for_sql should return true as needed' do
      assert Category.uhook_join_category_table_in_category_conditions_for_sql
    end

    test 'uhook_filtered_search should return locale scope' do
      assert_equal(
        [{:conditions => {:locale => 'ca'}}],
        Category.uhook_filtered_search({:locale => 'ca'})
      )
    end

    test 'uhook_filtered_search should not return locale scope if no locale filter' do
      assert_equal [], Category.uhook_filtered_search({})
    end

    test 'uhook_index_filters_should_return_locale_filter' do
      mock_categories_params :filter_locale => 'ca'
      assert_equal({:locale => 'ca'}, Ubiquo::CategoriesController.new.uhook_index_filters)
    end

    test 'uhook_new_from_name should return a category with given locale' do
      category = Category.uhook_new_from_name('name', {:locale => 'ca'})
      assert_equal 'ca', category.locale
    end

    test 'uhook_new_from_name should return a category with any locale by default' do
      category = Category.uhook_new_from_name('name')
      assert_equal 'any', category.locale.to_s
    end

    test 'uhook_index_search_subject should return locale filtered categories' do
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      Category.expects(:locale).with('ca', :all).returns(Category)
      assert_nothing_raised do
        Ubiquo::CategoriesController.new.uhook_index_search_subject.filtered_search
      end
    end

    test 'uhook_new_category should return translated category' do
      mock_categories_params :from => 1
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).returns('ca')
      Category.expects(:translate).with(1, 'ca', :copy_all => true)
      Ubiquo::CategoriesController.new.uhook_new_category
    end

    test 'uhook_show_category should not return false if current locale' do
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      assert_not_equal false, Ubiquo::CategoriesController.new.uhook_show_category(Category.new(:locale => 'ca'))
    end

    test 'uhook_show_category should redirect if not current locale' do
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      Ubiquo::CategoriesController.any_instance.expects(:ubiquo_category_set_categories_url).at_least_once.returns('')
      Ubiquo::CategoriesController.any_instance.expects(:redirect_to).at_least_once
      assert_equal false, Ubiquo::CategoriesController.new.uhook_show_category(Category.new(:locale => 'en'))
    end

    test 'uhook_edit_category should not return false if current locale' do
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      assert_not_equal false, Ubiquo::CategoriesController.new.uhook_edit_category(Category.new(:locale => 'ca'))
    end

    test 'uhook_edit_category should redirect if not current locale' do
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      Ubiquo::CategoriesController.any_instance.expects(:ubiquo_category_set_categories_url).at_least_once.returns('')
      Ubiquo::CategoriesController.any_instance.expects(:redirect_to).at_least_once
      assert_equal false, Ubiquo::CategoriesController.new.uhook_edit_category(Category.new(:locale => 'en'))
    end

    test 'uhook_create_category_should_return_new_category_with_current_locale' do
      mock_categories_params
      Ubiquo::CategoriesController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      category = Ubiquo::CategoriesController.new.uhook_create_category
      assert_kind_of Category, category
      assert_equal 'ca', category.locale
      assert category.new_record?
    end

    test 'uhook_destroy_category_should_destroy_category' do
      Category.any_instance.expects(:destroy).returns(:value)
      mock_categories_params :destroy_content => false
      assert_equal :value, Ubiquo::CategoriesController.new.uhook_destroy_category(Category.new)
    end

    test 'uhook_destroy_category_should_destroy_category_content' do
      Category.any_instance.expects(:destroy_content).returns(:value)
      mock_categories_params :destroy_content => true
      assert_equal :value, Ubiquo::CategoriesController.new.uhook_destroy_category(Category.new)
    end

    test 'uhook_category_filters_should_add_a_locale_filter' do
      filter_set = mock()
      filter_set.expects(:locale).returns(true)

      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_filters
      end

      assert I18n::UbiquoCategoriesController::Helper.uhook_category_filters(filter_set)
    end

    test 'uhook_edit_category_sidebar_should_return_show_translations_links' do
      mock_categories_helper
      I18n::UbiquoCategoriesController::Helper.expects(:show_translations).at_least_once.returns('links')
      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_edit_category_sidebar
      end
      assert_equal 'links', I18n::UbiquoCategoriesController::Helper.uhook_edit_category_sidebar(Category.new)
    end

    test 'uhook_new_category_sidebar should return show translations links' do
      mock_categories_helper
      I18n::UbiquoCategoriesController::Helper.expects(:show_translations).at_least_once.returns('links')
      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_new_category_sidebar
      end
      assert_equal 'links', I18n::UbiquoCategoriesController::Helper.uhook_new_category_sidebar(Category.new)
    end

    test 'uhook_category_index_actions should return translate and remove link if not current locale' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      category = set.categories.first

      mock_categories_helper
      I18n::UbiquoCategoriesController::Helper.expects(:current_locale).at_least_once.returns('en')
      I18n::UbiquoCategoriesController::Helper.expects(:ubiquo_category_set_category_path).with(set, category, :destroy_content => true)
      I18n::UbiquoCategoriesController::Helper.expects(:new_ubiquo_category_set_category_path).with(:from => category.content_id)
      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_index_actions
      end
      actions = I18n::UbiquoCategoriesController::Helper.uhook_category_index_actions set, category
      assert actions.is_a?(Array)
      assert_equal 2, actions.size
    end

    test 'uhook_category_index_actions should return removes and edit links if current locale' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      category = set.categories.first

      mock_categories_helper
      I18n::UbiquoCategoriesController::Helper.stubs(:current_locale).returns('ca')
      I18n::UbiquoCategoriesController::Helper.expects(:ubiquo_category_set_category_path).with(set, category, :destroy_content => true)

      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_index_actions
      end
      actions = I18n::UbiquoCategoriesController::Helper.uhook_category_index_actions set, category
      assert actions.is_a?(Array)
      assert_equal 3, actions.size
    end

    test 'uhook_category_form should return content_id field' do
      mock_categories_helper
      f = stub_everything
      f.expects(:hidden_field).with(:content_id).returns('')
      I18n::UbiquoCategoriesController::Helper.expects(:params).returns({:from => 100})
      I18n::UbiquoCategoriesController::Helper.expects(:hidden_field_tag).with(:from, 100).returns('')
      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_form
      end
      I18n::UbiquoCategoriesController::Helper.uhook_category_form(f)
    end

    test 'uhook_category_partial should return locale information' do
      set = create_category_set
      set.categories << ['category', {:locale => 'ca'}]
      category = set.categories.first

      mock_categories_helper
      I18n::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_partial
      end

      I18n::UbiquoCategoriesController::Helper.expects(:content_tag).with(:dt,
        Category.human_attribute_name("locale") + ':'
      ).returns ''
      I18n::UbiquoCategoriesController::Helper.expects(:content_tag).with(:dd,
        anything
      ).returns ''
      Locale.expects(:find_by_iso_code).with('ca')

      I18n::UbiquoCategoriesController::Helper.uhook_category_partial category
    end

    test 'uhook_categories_for_set should return set categories by locale' do
      # setup
      mock_categories_helper
      set = create_category_set
      set.categories << ['ca', {:locale => 'ca'}]
      catalan_category = set.categories.first
      translation = catalan_category.translate('jp', :copy_all => true)
      translation.save
      assert_equal 2, set.categories.reload.size

      I18n::UbiquoHelpers::Helper.expects(:current_locale).returns('ca')
      I18n::UbiquoHelpers::Helper.module_eval do
        module_function :uhook_categories_for_set
      end
      assert_equal(
        [catalan_category],
        I18n::UbiquoHelpers::Helper.uhook_categories_for_set(set)
      )
    end

    test 'uhook_categories_for_set should return categories by object locale' do
      # setup
      mock_categories_helper
      set = create_category_set
      set.categories << ['ca', {:locale => 'ca'}]
      catalan_category = set.categories.first
      translation = catalan_category.translate('jp', :copy_all => true)
      translation.save
      assert_equal 2, set.categories.reload.size

      I18n::UbiquoHelpers::Helper.expects(:current_locale).never
      I18n::UbiquoHelpers::Helper.module_eval do
        module_function :uhook_categories_for_set
      end

      object_class = mock(:is_translatable? => true)
      object = mock(:locale => 'jp', :class => object_class)
      assert_equal(
        [translation],
        I18n::UbiquoHelpers::Helper.uhook_categories_for_set(set, object)
      )
    end

    test 'categories_are_created_with_locale_any_if_unspecified' do
      set = create_category_set
      set.categories << 'Category'
      assert set.categories.first.in_locale?('any')
    end

    test 'categories_are_created_with_specified_locale' do
      set = create_category_set
      set.categories << ['Category', {:locale => :ca}]
      assert set.categories.first.in_locale?('ca')
    end

    test 'select_fittest with locale' do
      set = create_category_set
      set.categories << 'Category'
      category = Category.last
      category.update_attribute :locale, 'en'
      cat_category = category.translate('ca', :copy_all => true)
      cat_category.save
      assert_equal category, set.reload.select_fittest(category)
      assert_equal cat_category, set.select_fittest(category, :locale => 'ca')
      assert_equal cat_category, set.select_fittest('Category', :locale => 'ca')
    end

    test 'category adopts object locale' do
      i18n_categorize :city
      model = create_i18n_category_model
      model.city = 'Barcelona'
      assert_equal model.locale, model.city.locale
    end

    test 'categories can be translation_shared' do
      i18n_categorize :city, :translation_shared => true
      model = create_i18n_category_model
      model.city = 'Barcelona'
      translation = model.translate 'ca'
      translation.cities
      assert_kind_of Category, translation.city
      assert_equal 'Barcelona', translation.city.to_s
      assert_equal model.city.content_id, translation.city.content_id
      assert_equal 'en', translation.city.locale
    end

    test 'category_conditions_for_existent_category' do
      categorize :cities
      set = CategorySet.find_by_key('cities')
      set.categories << 'Barcelona' # ensure there is one
      category = set.categories.last

      assert_equal(
        ["#{Category.alias_for_association(:cities)}.content_id IN (?)", [category.content_id]],
        CategoryTestModel.category_conditions_for(:cities, category.name)[:conditions]
      )
    end

    test 'category_conditions_for_inexistent_category' do
      categorize :genre
      create_set :genres
      assert_equal(
        ["#{Category.alias_for_association(:genres)}.content_id IN (?)", [0]],
        CategoryTestModel.category_conditions_for(:genre, 'value')[:conditions]
      )
    end

    protected

    def i18n_categorize attr, options = {}
      CategoryTranslatableTestModel.class_eval do
        translatable :field
        categorized_with attr, options
      end
    end

  else
    puts 'ubiquo_i18n not found, omitting UbiquoCategories::Connectors::I18n tests'
  end

end

create_categories_test_model_backend
