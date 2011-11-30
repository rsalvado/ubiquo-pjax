require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoCategories::Connectors::BaseTest < ActiveSupport::TestCase

  Base = UbiquoCategories::Connectors::Base

  test 'should_load_correct_modules' do
    ::Category.expects(:include).with(Base::Category)
    ::CategorySet.expects(:include).with(Base::CategorySet)
    ::Ubiquo::CategoriesController.expects(:include).with(Base::UbiquoCategoriesController)
    ::ActiveRecord::Migration.expects(:include).with(Base::Migration)
    ::ActiveRecord::Base.expects(:include).with(Base::ActiveRecord::Base)
    ::Ubiquo::Extensions::Loader.expects(:append_helper).with(:UbiquoController, Base::UbiquoHelpers::Helper)
    Base.expects(:set_current_connector).with(Base)
    Base.load!
  end

  test 'should_set_current_connector_on_load' do
    save_current_categories_connector
    Base.load!
    assert_equal Base, Base.current_connector
    reload_old_categories_connector
  end

  test_each_connector(:ubiquo_categories) do

    test 'uhook_create_categories_table_should_create_table' do
      ActiveRecord::Migration.expects(:create_table).with(:categories, anything)
      ActiveRecord::Migration.uhook_create_categories_table {}
    end

    test 'uhook_create_category_relations_table_should_create_table' do
      ActiveRecord::Migration.expects(:create_table).with(:category_relations, anything)
      ActiveRecord::Migration.uhook_create_category_relations_table {}
    end

    test 'uhook_assign_to_set should add to set' do
      set = create_category_set
      set.categories.expects('<<').with{|category| category.to_s == 'category'}
      CategorySet.uhook_assign_to_set set, ['category'], set
    end

    test 'uhook_categorized_with should not raise' do
      assert_nothing_raised do
        CategorySet.uhook_categorized_with :field, {}
      end
    end

    test 'uhook_category_identifier_for_name should return a value' do
      set = create_category_set
      set.categories << 'category'
      assert_not_nil set.uhook_category_identifier_for_name(
        set.categories.first.name
      )
    end

    test 'uhook_select_fittest should return a category' do
      set = create_category_set
      set.categories << 'category'
      assert_kind_of Category, set.uhook_select_fittest(set.categories.first, {})
    end

    test 'uhook_category_identifier_condition should return a condition' do
      assert [String, Hash, Array].include?(Category.uhook_category_identifier_condition([], :dummy).class)
    end

    test 'uhook_filtered_search_in_category should return an array' do
      assert_kind_of Array, Category.uhook_filtered_search({})
    end

    test 'uhook_new_from_name should return a category' do
      category = Category.uhook_new_from_name('name', {})
      assert_kind_of Category, category
      assert_equal 'name', category.name
      assert category.new_record?
    end

    test 'uhook_index_filters_should_return_hash' do
      mock_categories_controller
      assert Ubiquo::CategoriesController.new.uhook_index_filters.is_a?(Hash)
    end

    test 'uhook_index_search_subject should return searchable' do
      mock_categories_controller
      assert_nothing_raised do
        Ubiquo::CategoriesController.new.uhook_index_search_subject.filtered_search
      end
    end

    test 'uhook_new_category should return new category' do
      mock_categories_controller
      category = Ubiquo::CategoriesController.new.uhook_new_category
      assert category.is_a?(Category)
      assert category.new_record?
    end

    test 'uhook_show_category should not break' do
      mock_categories_controller
      assert_nothing_raised do
        Ubiquo::CategoriesController.new.uhook_show_category Category.new
      end
    end

    test 'uhook_edit_category should not break' do
      mock_categories_controller
      assert_nothing_raised do
        Ubiquo::CategoriesController.new.uhook_edit_category Category.new
      end
    end

    test 'uhook_create_category_should_return_new_category' do
      mock_categories_controller
      category = Ubiquo::CategoriesController.new.uhook_create_category
      assert_kind_of Category, category
      assert category.new_record?
    end

    test 'uhook_destroy_category_should_destroy_category' do
      mock_categories_controller
      Category.any_instance.expects(:destroy).returns(:value)
      assert_equal :value, Ubiquo::CategoriesController.new.uhook_destroy_category(Category.new)
    end

    test 'uhook_category_filters_should_exist' do
      mock_categories_helper
      Base.current_connector::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_filters
      end
      assert_respond_to Base.current_connector::UbiquoCategoriesController::Helper, :uhook_category_filters
    end

    test 'uhook_edit_category_sidebar_should_return_string' do
      mock_categories_helper
      Base.current_connector::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_edit_category_sidebar
      end
      assert Base.current_connector::UbiquoCategoriesController::Helper.uhook_edit_category_sidebar(Category.new).is_a?(String)
    end

    test 'uhook_new_category_sidebar should return string' do
      mock_categories_helper
      Base.current_connector::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_new_category_sidebar
      end
      assert Base.current_connector::UbiquoCategoriesController::Helper.uhook_new_category_sidebar(Category.new).is_a?(String)
    end

    test 'uhook_category_index_actions should return array' do
      mock_categories_helper
      Base.current_connector::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_index_actions
      end
      assert Base.current_connector::UbiquoCategoriesController::Helper.uhook_category_index_actions(CategorySet.new, Category.new).is_a?(Array)
    end

    test 'uhook_category_form should return string' do
      mock_categories_helper
      f = stub_everything
      f.stub_default_value = ''
      Base.current_connector::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_form
      end
      assert Base.current_connector::UbiquoCategoriesController::Helper.uhook_category_form(f).is_a?(String)
    end

    test 'uhook_category_partial should return string' do
      mock_categories_helper
      Base.current_connector::UbiquoCategoriesController::Helper.module_eval do
        module_function :uhook_category_partial
      end
      assert_kind_of String, Base.current_connector::UbiquoCategoriesController::Helper.uhook_category_partial(Category.first)
    end

    test 'uhook_categories_for_set should return searchable' do
      mock_categories_helper
      set = create_category_set
      Base.current_connector::UbiquoHelpers::Helper.module_eval do
        module_function :uhook_categories_for_set
      end
      assert_nothing_raised do
        Base.current_connector::UbiquoHelpers::Helper.uhook_categories_for_set(set).filtered_search
      end
    end
  end

  # Define module mocks for testing
  class Base
    module Category; end
    module CategorySet; end
    module UbiquoCategoriesController; end
    module UbiquoHelpers
      module Helper; end
    end
    module Migration; end
    module ActiveRecord
      module Base; end
    end
  end

end
