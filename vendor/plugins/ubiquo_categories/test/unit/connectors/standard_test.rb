require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoCategories::Connectors::StandardTest < ActiveSupport::TestCase

  Standard = UbiquoCategories::Connectors::Standard

  def setup
    save_current_categories_connector
    Standard.load!
  end

  def teardown
    reload_old_categories_connector
  end


  test 'uhook_create_categories_table_should_create_table' do
    ActiveRecord::Migration.expects(:create_table).with(:categories)
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

  test 'uhook_category_identifier_for_name should return id' do
    set = create_category_set
    set.categories << 'category'
    assert_equal(
      set.categories.first.id,
      set.uhook_category_identifier_for_name(set.categories.first.name)
    )
  end

  test 'uhook_select_fittest should return the same category' do
    set = create_category_set
    set.categories << 'category'
    assert_equal set.categories.first, set.uhook_select_fittest(set.categories.first)
  end

  test 'uhook_category_identifier_condition should return a id condition' do
    assert_equal(
      ["#{CategoryRelation.alias_for_association('cities')}.category_id IN (?)", [1]],
      Category.uhook_category_identifier_condition([1], :cities)
    )
  end

  test 'uhook_join_category_table_in_category_conditions_for_sql should return false for efficiency' do
    assert !Category.uhook_join_category_table_in_category_conditions_for_sql
  end

  test 'uhook_filtered_search should return no scopes' do
    assert_equal [], Category.uhook_filtered_search({})
  end

  test 'uhook_index_filters_should_return_empty_hash' do
    assert_equal({}, Ubiquo::CategoriesController.new.uhook_index_filters)
  end

  test 'uhook_index_search_subject should return category class' do
    assert_equal Category, Ubiquo::CategoriesController.new.uhook_index_search_subject
  end

  test 'uhook_new_category should return new category' do
    category = Ubiquo::CategoriesController.new.uhook_new_category
    assert category.is_a?(Category)
    assert category.new_record?
  end

  test 'uhook_show_category should return true' do
    assert Ubiquo::CategoriesController.new.uhook_show_category(Category.new)
  end

  test 'uhook_edit_category should return true' do
    assert Ubiquo::CategoriesController.new.uhook_edit_category(Category.new)
  end

  test 'uhook_create_category_should_return_new_category' do
    mock_categories_params
    category = Ubiquo::CategoriesController.new.uhook_create_category
    assert_kind_of Category, category
    assert category.new_record?
  end

  test 'uhook_destroy_category_should_destroy_category' do
    Category.any_instance.expects(:destroy).returns(:value)
    assert_equal :value, Ubiquo::CategoriesController.new.uhook_destroy_category(Category.new)
  end

  test 'uhook_category_filters_should_exist' do
    Standard::UbiquoCategoriesController::Helper.module_eval do
      module_function :uhook_category_filters
    end
    assert_respond_to Standard::UbiquoCategoriesController::Helper, :uhook_category_filters
  end

  test 'uhook_new_category_sidebar should return empty string' do
    mock_categories_helper
    Standard::UbiquoCategoriesController::Helper.module_eval do
      module_function :uhook_new_category_sidebar
    end
    assert_equal '', Standard::UbiquoCategoriesController::Helper.uhook_new_category_sidebar(Category.new)
  end

  test 'uhook_category_index_actions should return array with edit and remove' do
    set = create_category_set
    set.categories << 'category'
    category = set.categories.first

    mock_categories_helper
    Standard::UbiquoCategoriesController::Helper.module_eval do
      module_function :uhook_category_index_actions
    end

    Standard::UbiquoCategoriesController::Helper.expects(:t).at_least_once.returns('t')
    Standard::UbiquoCategoriesController::Helper.expects(:link_to).with('t', [:edit, :ubiquo, set, category], {:class => 'btn-edit'})
    Standard::UbiquoCategoriesController::Helper.expects(:link_to).with('t', [:ubiquo, set, category], {:confirm => 't', :method => :delete, :class => 'btn-delete'})

    actions = Standard::UbiquoCategoriesController::Helper.uhook_category_index_actions set, category
    assert actions.is_a?(Array)
    assert_equal 2, actions.size
  end

  test 'uhook_category_form should return empty string' do
    mock_categories_helper
    f = stub_everything
    Standard::UbiquoCategoriesController::Helper.module_eval do
      module_function :uhook_category_form
    end
    assert_equal '', Standard::UbiquoCategoriesController::Helper.uhook_category_form(f)
  end

  test 'uhook_category_partial should return empty string' do
    mock_categories_helper
    Standard::UbiquoCategoriesController::Helper.module_eval do
      module_function :uhook_category_partial
    end
    assert_equal '', Standard::UbiquoCategoriesController::Helper.uhook_category_partial(Category.first)
  end

  test 'uhook_categories_for_set should return set categories' do
    mock_categories_helper
    set = create_category_set
    set.categories << 'category'
    Standard::UbiquoHelpers::Helper.module_eval do
      module_function :uhook_categories_for_set
    end
    assert_equal(
      set.categories,
      Standard::UbiquoHelpers::Helper.uhook_categories_for_set(set)
    )
  end

end
