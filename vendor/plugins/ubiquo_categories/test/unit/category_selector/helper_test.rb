require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoCategories::CategorySelector::HelperTest < ActionView::TestCase

  connector = UbiquoCategories::Connectors::Base.current_connector
  self.send(:include, connector::UbiquoHelpers::Helper)

  def setup
    @set = CategorySet.create(:name => "Tags", :key => "tags")
    @set.categories.build(:name => "Red")
    @set.categories.build(:name => "Blue")
    @set.save
  end

  def test_category_selector_in_form_object
    categorize :tags
    object = CategoryTestModel.new
    self.expects(:category_selector).with(:post, :tags, {:object => object}, {})
    form_for(:post, object, :url => '') do |f|
      f.category_selector :tags
    end
  end

  def test_category_selector_in_form_object_with_a_singular_category_set_key
    @set = CategorySet.create(:name => "Section", :key => "section")
    @set.categories.build(:name => "one")
    @set.categories.build(:name => "two")
    @set.save

    categorize :section

    form_for(:post, CategoryTestModel.new, :url => '') do |f|
      concat f.category_selector(:section, :type => 'checkbox')
      concat f.category_selector(:section, :type => 'select')
    end

    doc = HTML::Document.new(output_buffer)
    assert_select doc.root, 'form' do
      assert_select 'input[type=checkbox]'
      assert_select 'select'
    end
  end

  def test_prints_selector_with_explicit_type
    categorize :tags
    form_for(:post, CategoryTestModel.new, :url => '') do |f|
      concat f.category_selector(:tags, :type => 'checkbox')
      concat f.category_selector(:tags, :type => 'select')
    end

    doc = HTML::Document.new(output_buffer)
    assert_select doc.root, 'form' do
      assert_select 'input[type=checkbox]'
      assert_select 'select'
    end
  end

  def test_from_options_available
    categorize :tags
    create_set :cities
    categorize(:using_from, :from => :cities)

    assert_nothing_raised do
      form_for(:post, CategoryTestModel.new, :url => '') do |f|
        concat f.category_selector(:using_from)
      end
    end

  end

  def test_category_selector_should_be_autocomplete_when_many_categories
    categorize :tags
    current_categories_amount = @set.categories.size
    max = Ubiquo::Config.context(:ubiquo_categories).get(:max_categories_simple_selector)

    (max + 1 - current_categories_amount).times do
      @set.categories << rand.to_s
    end
    assert_equal max + 1, @set.categories.size

    self.expects('category_autocomplete_selector').returns('')
    category_selector 'name', :tags, :object => CategoryTestModel.new
  end

  def test_category_selector_should_be_select_when_one_possible_category
    categorize :tags
    categorize :city, :size => 1
    create_set :cities

    self.expects('category_select_selector').returns('')
    category_selector 'name', :city, :object => CategoryTestModel.new
  end

  def test_category_selector_should_be_checkbox_when_one_possible_category
    categorize :tags
    categorize :city, :size => :many
    create_set :cities

    self.expects('category_checkbox_selector').returns('')
    category_selector 'name', :city, :object => CategoryTestModel.new
  end

  def test_category_selector_have_fieldset_and_legend_if_type_is_checkbox
    categorize :tags
    output = category_selector 'name', :tags, :object => CategoryTestModel.new, :type => 'checkbox'
    doc = HTML::Document.new(output)
    assert_select doc.root, 'fieldset' do
      assert_select 'legend'
    end
  end

  def test_category_selector_have_div_instead_of_fieldset_if_type_is_select
    categorize :tags
    output = category_selector 'name', :tags, :object => CategoryTestModel.new, :type => 'select'
    doc = HTML::Document.new(output)
    assert_select doc.root, 'div'
  end

  def test_category_selector_have_div_instead_of_fieldset_if_type_is_autocomplete
    categorize :tags
    output = category_selector 'name', :tags, :object => CategoryTestModel.new, :type => 'autocomplete'
    doc = HTML::Document.new(output)
    assert_select doc.root, 'div'
  end

  def test_category_selector_should_show_new_buttons_if_is_editable
    categorize :tags
    object = CategoryTestModel.new
    output = category_selector 'name', :tags, { :object => object }, { :id => 'html_id' }
    doc = HTML::Document.new(output)
    assert_select doc.root, 'div[id=html_id]'
    assert_select doc.root, '.new_category_controls' do
      assert_select doc.root, '.bt-add-category'
      assert_select doc.root, '.add_new_category' do
        assert_select doc.root, '.bt-create-category'
      end
    end
  end

  def test_category_selector_shouldnt_show_new_category_buttons
    categorize :tags
    @set.update_attributes(:is_editable => false)
    object = CategoryTestModel.new
    output = category_selector 'name', :tags, { :object => object }, { :id => 'html_id' }
    doc = HTML::Document.new(output)
    # first, check if category selector is printed
    assert_select doc.root, 'div[id=html_id]'
    # now, check that all new categories controls aren't displayed
    assert_select doc.root, '.new_category_controls', 0
    assert_select doc.root, '.category_selector_new', 0
    assert_select doc.root, '.add_new_category', 0
  end

  def test_category_selector_shouldnt_show_new_category_buttons_with_hide_controls_option
    categorize :tags
    object = CategoryTestModel.new
    output = category_selector(
      'name',
      :tags,
      { :object => object , :type => 'checkbox', :hide_controls => true },
      {:id => 'html_id'})
    doc = HTML::Document.new(output)
    # first, check if category selector is printed
    assert_select doc.root, 'fieldset[id=html_id]'
    # now, check that all new categories controls aren't displayed
    assert_select doc.root, '.new_category_controls', 0
    assert_select doc.root, '.bt-add-category', 0
    assert_select doc.root, '.bt-create-category', 0

    object2 = CategoryTestModel.new
    output2 = category_selector('name',
      :tags,
      { :object => object2 , :type => 'checkbox', :hide_controls => false },
      {:id => 'html_id'})
    doc2 = HTML::Document.new(output2)
    # first, check if category selector is printed
    assert_select doc2.root, 'fieldset[id=html_id]'
    # now, check that all new categories controls aren't displayed
    assert_select doc2.root, '.new_category_controls', 1
    assert_select doc2.root, '.bt-add-category', 1
    assert_select doc2.root, '.bt-create-category', 1
  end

  def test_fieldset_has_html_options
    categorize :tags
    object = CategoryTestModel.new
    output = category_selector 'name', :tags, {:object => object, :type => 'checkbox'}, {:id => 'html_id'}
    doc = HTML::Document.new(output)
    assert_select doc.root, 'fieldset[id=html_id]'
  end

  def test_legend_uses_name_if_present
    categorize :tags
    object = CategoryTestModel.new
    output = category_selector 'name', :tags, {:object => object, :name => 'legend', :type => 'checkbox'}
    doc = HTML::Document.new(output)
    assert_select doc.root, 'legend', 'legend'
  end

  def test_legend_uses_relation_name_if_no_name
    categorize :tags
    output = category_selector 'name', :tags, {:object => CategoryTestModel.new, :type => 'checkbox'}
    doc = HTML::Document.new(output)
    assert_select doc.root, 'legend', CategoryTestModel.human_attribute_name(:tags)
  end

  def test_category_select_selector
    categorize :tags
    object = CategoryTestModel.new
    assert_nothing_raised do
      category_select_selector object, 'name', :tags, @set.categories, @set
    end
  end

  def test_should_raise_categorization_not_found_when_baseclass_have_not_been_categorized
    object = EmptyTestModelSubOne.new
    assert_raise UbiquoCategories::CategorizationNotFoundError do
      category_selector 'name', :tags, {:object => object}, {:id => 'html_id'}
    end
    object = EmptyTestModelSubTwo.new
    assert_raise UbiquoCategories::CategorizationNotFoundError do
      category_selector 'name', :tags, {:object => object}, {:id => 'html_id'}
    end
  end

  def test_should_not_raise_categorization_not_found_when_baseclass_have_been_categorized
    categorize_base :tags
    object = CategoryTestModelSubOne.new
    assert_nothing_raised do
      category_selector 'name', :tags, {:object => object}, {:id => 'html_id'}
    end
    object = CategoryTestModelSubTwo.new
    assert_nothing_raised do
      category_selector 'name', :tags, {:object => object}, {:id => 'html_id'}
    end
  end

  def test_category_select_selector_with_default_option
    object = CategoryTestModel.new
    options = {:default => 'Red'}
    output = category_select_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    assert_select doc.root, 'select' do
      assert_select 'option[selected=selected][value=Red]'
    end
  end

  def test_category_select_selector_respect_value_as_selected_option
    object = CategoryTestModel.new
    object.tags << 'Blue'
    options = {:default => 'Red'}
    output = category_select_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    assert_select doc.root, 'select' do
      assert_select 'option[selected=selected][value=Blue]'
    end
  end

  def test_category_select_selector_should_ignore_default_option_if_itsnt_new_record
    object = CategoryTestModel.create(:field => 'test')
    options = {:default => 'Red'}
    output = category_select_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    red_option = doc.root.find(:tag => "option", :attributes => { :value => 'Red' })
    assert red_option.match(:attributes => { :selected => false })
  end

  def test_category_checkbox_selector_with_default_option
    categorize :tags
    object = CategoryTestModel.new
    options = {:default => 'Red'}
    output = category_checkbox_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    red_check = doc.root.find({:attributes => { :type => 'checkbox', :value => 'Red' }})
    assert red_check.match(:attributes => { :checked => true })
  end

  def test_category_checkbox_selector_with_multiple_default_option
    categorize :tags
    object = CategoryTestModel.new
    options = {:default => ['Red','Blue']}
    output = category_checkbox_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    red_check = doc.root.find({:attributes => { :type => 'checkbox', :value => 'Red' }})
    blue_check = doc.root.find({:attributes => { :type => 'checkbox', :value => 'Blue' }})
    assert red_check.match(:attributes => { :checked => true })
    assert blue_check.match(:attributes => { :checked => true })
  end

  def test_category_checkbox_selector_should_ignore_default_option_if_itsnt_new_record
    categorize :tags
    object = CategoryTestModel.create(:field => 'test')
    options = {:default => 'Red'}
    output = category_checkbox_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    red_check = doc.root.find({:attributes => { :type => 'checkbox', :value => 'Red' }})
    assert red_check.match(:attributes => { :checked => false })
  end

  def test_category_checkbox_selector_respect_values_as_checked_options
    categorize :tags, :size => :many
    object = CategoryTestModel.new
    object.tags += ['Blue', 'Yellow', 'Green']
    options = {:default => 'Red'}
    output = category_checkbox_selector object, 'name', :tags, @set.categories, @set, options
    doc = HTML::Document.new(output)
    assert_select doc.root, 'input[type=checkbox][checked=checked][value=Blue]'
    assert_select doc.root, 'input[type=checkbox][checked=checked][value=Yellow]'
    assert_select doc.root, 'input[type=checkbox][checked=checked][value=Green]'
  end

end

create_categories_test_model_backend
