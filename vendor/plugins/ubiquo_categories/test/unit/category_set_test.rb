require File.dirname(__FILE__) + '/../test_helper'

class CategorySetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_category_set
    assert_difference 'CategorySet.count' do
      category_set = create_category_set
      assert !category_set.new_record?, "#{category_set.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_unique_key
    assert_difference 'CategorySet.count', 1 do
      category_set = create_category_set :key=> 'my_key'
      category_set = create_category_set :key=> category_set.key
      assert category_set.errors.on(:key)
      category_set = create_category_set :key=> category_set.key.upcase
      assert category_set.errors.on(:key)
    end
  end

  def test_should_require_name
    assert_no_difference 'CategorySet.count' do
      category_set = create_category_set(:name => "")
      assert category_set.errors.on(:name)
    end
  end

  def test_should_have_categories
    category_set = create_category_set
    assert_equal [], category_set.categories
  end

  def test_should_allow_add_string_categories
    category_set = create_category_set
    category_set.categories << 'category'
    assert_equal 1, category_set.categories.size
    assert_equal 'category', category_set.categories.first.name
    assert_raise ActiveRecord::AssociationTypeMismatch do
      category_set.categories << 1
    end
  end

  def test_should_allow_add_hash_categories
    category_set = create_category_set
    assert_difference 'Category.count', 3 do
      category_set.categories << {'parent' => ['child1', 'child2']}
    end
    assert_equal 3, category_set.categories.size
    assert_equal 'parent', Category.find_by_name('child1').parent.name
    assert_equal 'parent', Category.find_by_name('child2').parent.name
    assert_nil Category.find_by_name('parent').parent
  end

  def test_should_filter_by_name
    CategorySet.destroy_all
    category_set_1,category_set_2,category_set_3 = [
      create_category_set(:name => "try to find me"),
      create_category_set(:name => "try to FinD me"),
      create_category_set(:name => "I don't appear"),
    ]

    assert_equal_set [category_set_1,category_set_2], CategorySet.filtered_search({:text => "find"})
  end

  def test_should_allow_creation_by_default
    set = CategorySet.create(:name => 'name', :key => 'key')
    assert set.is_editable?
  end

  def test_should_not_allow_creation
    set = create_category_set
    set.is_not_editable!
    assert_raise UbiquoCategories::CreationNotAllowed do
      set.categories << 'Category'
    end
  end

  def test_should_allow_creation
    set = create_category_set
    set.is_editable!
    assert_nothing_raised do
      set.categories << 'Category'
    end
  end

  def test_is_editable_method
    set = create_category_set :is_editable => true
    assert set.is_editable?
    set.update_attribute :is_editable, false
    assert !set.is_editable?
  end

  def test_only_one_category_with_same_name_coexist_in_the_same_set
    set = create_category_set
    assert_difference 'Category.count' do
      set.categories << 'Unique'
    end
    assert_no_difference 'Category.count' do
      set.categories << 'Unique'
    end
  end

  def test_multiple_categories_with_same_name_can_coexist_in_different_sets
    set_1 = create_category_set
    set_2 = create_category_set
    assert_difference 'Category.count' do
      set_1.categories << 'Unique'
    end
    assert_difference 'Category.count' do
      set_2.categories << 'Unique'
    end
  end

  def test_should_ignore_categories_with_blank_value
    set = create_category_set(:is_editable => false)
    assert_no_difference 'Category.count' do
      set.categories << ['']
      set.categories << [[' ']]
      set.categories << '                 '
    end
  end

  def test_select_fittest_with_string
    set = create_category_set
    set.categories << 'Category'
    category = Category.last
    assert_equal category, set.select_fittest('Category')
  end

  def test_select_fittest_with_string_case_insensitive
    set = create_category_set
    set.categories << 'Category'
    category = Category.last
    assert_equal category, set.select_fittest('cAtEgOrY')
  end
  
  def test_select_fittest_with_category
    set = create_category_set
    set.categories << 'Category'
    category = Category.last
    assert_equal category, set.select_fittest(category)
  end

end
