require File.dirname(__FILE__) + "/../../test_helper.rb"
require 'mocha'

class UbiquoCategories::ActiveRecordTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_categorized_with
    assert_nothing_raised do
      CategoryTestModel.class_eval do
        categorized_with :city
      end
    end
  end

  def test_categorized_creates_assignation_method
    categorize :city
    assert_nothing_raised do
      model = create_category_model
      model.city = 'City'
    end
  end

  def test_categorized_creates_retrieval_method
    categorize :city
    assert_nothing_raised do
      model = create_category_model
      model.city
    end
  end

  def test_categorized_stores_and_returns_category
    categorize :city
    model = create_category_model
    model.city = 'City'
    assert_equal 'City', model.city.to_s
    assert_equal Category, model.city.class
  end

  def test_categorized_creates_has_many_category_relations
    categorize :city
    model = create_category_model
    assert_nothing_raised do
      assert_equal [], model.category_relations
    end
  end

  def test_categorized_with_defaults_to_size_1
    categorize :city
    assert_raise UbiquoCategories::LimitError do
      model = create_category_model
      model.city = 'City1##City2'
    end
  end

  def test_is_full_method
    categorize :cities, :size => 2
    model = create_category_model
    assert !model.cities.is_full?
    model.cities << 'London'
    assert !model.cities.is_full?
    model.cities << 'Tokyo'
    assert model.cities.is_full?
  end

  def test_category_filter_should_not_return_read_only_instances
    categorize :cities
    CategoryTestModel.class_eval do
      named_scope :city, lambda{|value|
        category_conditions_for(:cities, value).merge(:order => 'field asc')
      }
    end

    c = Category.create(:name => 'city1', :category_set_id => CategorySet.find_by_key('cities').id)
    model = CategoryTestModel.create(:field => 'name_field')
    model.cities << c
    ctm = CategoryTestModel.city('city1').find(:first, :conditions => ['field = ?', 'name_field'])
    ctm.field = 'name_field_2'
    assert_nothing_raised do
      ctm.save
    end
  end

  def test_categorized_store_one_string_element
    categorize :city
    model = create_category_model
    model.city = 'City'
    assert_kind_of Category, model.city
    assert_equal 1, model.category_relations.size
  end

  def test_categorized_store_many_string_elements
    categorize :cities, :size => :many
    model = create_category_model
    model.city = 'City1##City2'
    assert_kind_of Array, model.cities
    assert_equal 2, model.category_relations.size
    assert_equal 'City1', model.cities.first.to_s
    assert_equal 'City2', model.cities.last.to_s
  end

  def test_categorized_store_many_string_elements_with_different_separator
    categorize :cities, :size => :many, :separator => '-'
    model = create_category_model
    model.cities = 'City1-City2'
    assert_kind_of Array, model.cities
    assert_equal 2, model.category_relations.size
    assert_equal 'City1', model.cities.first.to_s
    assert_equal 'City2', model.cities.last.to_s
  end

  def test_categorized_uses_category_set_pluralizing_name
    categorize :city
    categorize :cities, :size => :many
    model = create_category_model
    CategorySet.expects('find_by_key').with('cities').times(2).returns(category_sets(:cities))
    model.city = 'Amsterdam' # pluralizes city to cities
    model.cities = 'Barcelona' # maintains cities
  end

  def test_categorized_creates_category_inside_proper_set
    categorize :city, :size => :many
    set = category_sets(:cities)
    assert_equal [], set.categories
    assert_difference 'Category.count', 2 do
      model = create_category_model
      model.cities = 'Barcelona##Athens'
    end
    assert_equal 2, set.reload.categories.count
  end

  def test_categorized_retrieves_category_inside_proper_set
    categorize :city, :size => :many, :separator => '##'
    set = category_sets(:cities)
    assert_equal [], set.categories
    set.categories = Category.create(:name => 'Barcelona'), Category.create(:name => 'Athens')
    model = create_category_model
    assert_no_difference 'Category.count' do
      model.cities = 'Barcelona##Athens'
    end
    assert_equal set, model.cities.first.category_set
    assert_equal 2, set.reload.categories.count
  end

  def test_categorized_retrieves_categories_in_proper_order_through_association
    categorize :section
    categorize :colors
    section_set = CategorySet.create(:key => 'section', :name => 'Section')
    colors_set  = CategorySet.create(:key => 'colors', :name => 'Colors')
    section_set.categories = %( admin shop design ).map { |s| Category.create(:name => s) }
    colors_set.categories  = %( blue red green ).map { |c| Category.create(:name => c) }
    m = create_category_model.class # We create a record without categories
    m.create(:field => 'one',   :section => 'admin',  :colors => 'red')
    m.create(:field => 'two',   :section => 'design', :colors => 'blue')
    m.create(:field => 'three', :section => 'shop',   :colors => 'green')
    assert [1,2,3,4], m.find(:all, :include => :sections, :order => 'categories.name asc').map(&:id)
    assert [4,3,2,1], m.find(:all, :include => :sections, :order => 'categories.name desc')
    assert [1,3,4,2], m.find(:all, :include => :colors,   :order => 'categories.name asc').map(&:id)
    assert [2,4,3,1], m.find(:all, :include => :colors,   :order => 'categories.name desc').map(&:id)
  end

  def test_should_raise_if_set_does_not_exist
    categorize :unknown
    model = create_category_model
    assert_raise UbiquoCategories::SetNotFoundError do
      model.unknown = 'tag'
    end
  end

  def test_from_option_has_preference
    create_set :cities
    categorize :cities, :from => :group_of_cities
    model = create_category_model
    assert_raise UbiquoCategories::SetNotFoundError do
      model.cities = 'Barcelona'
    end
  end

  def test_from_option_retrieves_from_correct_set
    set = create_set :group_of_cities
    categories = ['Athens', 'Barcelona']
    categorize :cities, :from => :group_of_cities, :size => :many
    model = create_category_model
    assert_nothing_raised UbiquoCategories::SetNotFoundError do
      model.cities = categories
      assert_equal categories, model.cities.map(&:name)
      assert_equal categories, set.categories.map(&:name)
    end
  end

  def test_assignation_accepts_strings_and_category_instances
    categorize :cities, :size => :many
    model = create_category_model
    model.cities << Category.create(:category_set => category_sets(:cities), :name => 'City')
    model.cities << 'Athens'
    assert_equal 2, model.cities.count
  end

  def test_two_different_categorizations_do_not_conflict
    categorize :cities
    categorize :countries
    create_set :countries
    model = create_category_model
    model.cities << 'Barcelona'
    model.countries << 'Japan'
    assert_equal 1, model.cities.count
    assert_equal 1, model.countries.count
    assert_equal 'Barcelona', model.cities.first.name
    assert_equal 'Japan', model.countries.first.name
  end

  def test_has_category_in_plural_categorizations
    categorize :cities, :size => :many, :separator => ','
    model = create_category_model
    model.cities = ['Barcelona', 'Athens']
    tokyo_model = create_category_model
    tokyo_model.cities = 'Tokyo'

    assert model.cities.has_category?('Barcelona')
    assert !model.cities.has_category?('Tokyo')

    barcelona = Category.find_by_name('Barcelona')
    tokyo = Category.find_by_name('Tokyo')
    assert model.cities.has_category?(barcelona)
    assert !model.cities.has_category?(tokyo)
  end

  def test_has_category_in_singular_categorizations
    categorize :city
    model = create_category_model
    model.city = 'Barcelona'
    tokyo_model = create_category_model
    tokyo_model.city = 'Tokyo'

    assert_equal 'Barcelona', model.city.to_s
    assert model.city.has_category?('Barcelona')
    assert !model.city.has_category?('Tokyo')

    barcelona = Category.find_by_name('Barcelona')
    tokyo = Category.find_by_name('Tokyo')
    assert model.city.has_category?(barcelona)
    assert !model.cities.has_category?(tokyo)
  end

  def test_updating_relation_does_not_create_unneeded_instances
    categorize :cities, :size => :many, :separator => ','
    model = create_category_model
    model.cities << 'Barcelona'
    original_id = model.category_relations.first.id
    assert_difference 'CategoryRelation.count', 1 do
      model.cities = 'Barcelona,Athens'
    end
    assert_equal original_id, model.reload.category_relations.first.id
    assert_equal original_id + 1, model.category_relations.last.id
  end

  def test_categorizations_are_sorted_by_position
    categorize :cities, :size => :many, :separator => ','
    model = create_category_model
    model.cities = 'Barcelona,Athens'
    assert_equal 2, model.category_relations.count
    first = model.category_relations.first
    last = model.category_relations.last
    first.update_attribute :position, 2
    last.update_attribute :position, 1
    assert_not_equal first, model.reload.category_relations.first
    assert_equal first, model.reload.category_relations.last
  end

  def test_categorize_options
    categorize :cities, :size => :many
    categorize :genders, :size => 2, :separator => '/'
    assert_equal :many, CategoryTestModel.categorize_options(:cities)[:size]
    assert_equal 2, CategoryTestModel.categorize_options(:genders)[:size]
    assert_equal '/', CategoryTestModel.categorize_options(:genders)[:separator]
  end

  def test_categorize_options_works_for_singular_and_plural
    categorize :genre, :size => 2, :separator => '/'
    assert_not_nil CategoryTestModel.categorize_options(:genre)
    assert_not_nil CategoryTestModel.categorize_options(:genres)
  end

  def test_assignation_deletes_old_relations
    categorize :cities, :size => :many
    model = create_category_model
    model.cities = ['Barcelona', 'Tokyo']
    model.cities = ['Barcelona']
    assert_equal ['Barcelona'], model.cities.map(&:name)
    assert_equal 1, model.category_relations.count
  end

  def test_will_be_full
    categorize :cities, :size => 2
    model = create_category_model
    model.cities = ['Barcelona']
    assert model.cities.will_be_full?(['Tokyo', 'London', 'Paris'])
    assert !model.cities.will_be_full?(['Tokyo', 'London'])
    assert !model.cities.will_be_full?(['Tokyo', 'Barcelona'])
  end

  def test_assign_categories_when_new_record
    categorize :cities, :size => 2
    model = CategoryTestModel.new
    model.cities = ['Barcelona']
    model.save
    assert_equal ['Barcelona'], model.cities.map(&:name)
    assert_equal 'cities', model.category_relations.first.attr_name
  end

  def test_should_not_assign_blank_category
    categorize :cities, :size => 2
    model = create_category_model
    model.cities = ['', 'Barcelona']
    assert_equal ['Barcelona'], model.cities.map(&:name)
    assert_equal 1, model.category_relations.count
  end

  def test_should_not_assign_repeated_category
    categorize :cities, :size => 2
    model = create_category_model
    model.cities = ['Barcelona', 'Barcelona']
    assert_equal ['Barcelona'], model.cities.map(&:name)
    assert_equal 1, model.category_relations.count
  end

  def test_category_conditions_for_is_a_hash
    categorize :genre
    create_set :genres
    assert_kind_of Hash, CategoryTestModel.category_conditions_for('genre', 'value')
    assert_kind_of Hash, CategoryTestModel.category_conditions_for(:genre, 'value')
  end

  def test_field_named_scope
    create_set :cities
    categorize :cities, :size => 2
    model_1 = create_category_model
    model_1.cities = ['Barcelona', 'Tokyo']
    model_2 = create_category_model
    model_2.cities = ['Barcelona', 'London']
    model_3 = create_category_model
    model_3.cities = []

    assert_equal_set([model_1, model_2], CategoryTestModel.cities('Barcelona'))
    assert_equal_set([model_2], CategoryTestModel.cities('London'))
    assert_equal_set [], CategoryTestModel.cities()
  end

  def test_field_named_scope_does_not_repeat_results
    create_set :cities
    categorize :cities, :size => 2
    model_1 = create_category_model
    model_1.cities = ['Barcelona', 'Tokyo']
    model_2 = create_category_model
    model_2.cities = ['Barcelona', 'London']
    model_3 = create_category_model
    model_3.cities = []

    assert_equal(
      [model_1, model_2],
      CategoryTestModel.cities('Barcelona', 'Tokyo').\
        all(:order => 'category_test_models.id')
    )
  end

  def test_field_named_scope_scope_multiple
    categorize :cities, :size => 2
    create_set :cities
    categorize :genre
    create_set :genres

    model_1 = create_category_model
    model_1.cities = ['Barcelona', 'Tokyo']
    model_1.genre = 'Male'
    model_2 = create_category_model
    model_2.cities = ['Barcelona', 'London']
    model_2.genre = 'Female'
    model_3 = create_category_model
    model_3.cities = []
    model_3.genre = 'Male'

    assert_equal_set([model_1], CategoryTestModel.cities('Barcelona').genre('Male'))
    assert_equal_set([model_2], CategoryTestModel.genre('Female').cities('London'))

    model_2.genre = 'Male'

    assert_equal_set(
      [model_1, model_2],
      CategoryTestModel.genre('Male').cities('Barcelona')
    )

    assert_equal_set([], CategoryTestModel.genre('Female').cities('Tokyo'))
    assert_equal_set [], CategoryTestModel.cities().genre('Male')
    assert_equal_set [], CategoryTestModel.genre('Male').cities()
  end

  def test_with_field_no_set
    categorize :things, :size => 2
    assert_raise UbiquoCategories::SetNotFoundError do
      CategoryTestModel.things []
    end
  end

end

create_categories_test_model_backend
