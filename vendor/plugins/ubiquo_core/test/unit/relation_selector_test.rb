require File.dirname(__FILE__) + '/../test_helper'
require 'ubiquo/relation_selector'


class RelationSelectorTest < ActionView::TestCase

  include Ubiquo::RelationSelector::Helper

  test "should_create_right_selector" do
    #Select, checkboxes, autocomplete
    obj = TestOnlyModel.new

    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj,
      :type => :autocomplete)
    doc = HTML::Document.new(r)
    assert_select doc.root, 'script'

    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj,
      :type => :select)
    doc = HTML::Document.new(r)
    assert_select doc.root, 'select'

    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj,
      :type => :checkbox)
    doc = HTML::Document.new(r)
    assert_select doc.root, 'input'

  end

  test "should_display_owned_value" do
    #Display all options with the instance choice selected
    obj1 = TestOnlyModel.create(:name => 'first')
    obj2 = TestOnlyModelTwo.create(:title => 'second')
    obj3 = TestOnlyModelTwo.create(:title => 'third')

    obj1.test_only_model_twos << obj2

    r = relation_selector('test_only_model',
      :test_only_model_twos,
      :object => obj1,
      :type => :checkbox)

    doc = HTML::Document.new(r)
    assert_select doc.root, 'input[type=checkbox][checked=checked]', 1
    assert_select doc.root, 'input[type=hidden]', 1
  end

  test "should_display_owned_values" do
    #Display all options with the instance choices selected
    object = prepare_relation_selector_instances

    r = relation_selector('test_only_model',
      :test_only_model_twos,
      :object => object,
      :type => :checkbox)

    doc = HTML::Document.new(r)
    assert_select doc.root, 'input[type=checkbox][checked=checked]', 2
    assert_select doc.root, 'input[type=hidden]', 1

  end

  test "should_display_owned_values in autocomplete selector" do
    object = prepare_relation_selector_instances

    r = relation_selector('test_only_model',
      :test_only_model_twos,
      :object => object,
      :type => :autocomplete)

    doc = HTML::Document.new(r)
    error_message = 'autocomplete does not look as selecting the "%s" relation'
    object.test_only_model_twos.map(&:title).each do |child|
      assert_select doc.root, 'script', Regexp.new(child), error_message % child
    end
  end

  test "should display single owned value in autocomplete selector" do
    object = prepare_relation_selector_instances

    related_instance = object.test_only_model_twos.first
    related_instance.update_attribute :test_only_model_id, object.id
    r = relation_selector('test_only_model_two',
      :test_only_model,
      :object => related_instance,
      :type => :autocomplete)

    doc = HTML::Document.new(r)
    error_message = 'autocomplete does not look as selecting the "%s" relation'
    assert_select doc.root, 'script', Regexp.new(object.name), error_message % object.name
  end

  test "should_use_desired_name" do
    obj1 = TestOnlyModel.create(:name => 'first')
    obj2 = TestOnlyModelTwo.create(:arbitrary_name => 'second', :title => 'no_name')
    obj3 = TestOnlyModelTwo.create(:arbitrary_name => 'third', :title => 'no_name')

    obj1.test_only_model_two = obj2
    obj1.save

    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :name_field => 'arbitrary_name',
      :type => :select)

    doc = HTML::Document.new(r)
    assert_select doc.root, 'select' do |lk|
      assert_select lk.first, 'option' do |opt|
        opt.each do |s_opt|
          assert_equal obj2.arbitrary_name, s_opt.children.first.content if s_opt['selected'].present?
        end
      end
    end
  end

  test "should_use_default_field_as_title" do
    obj1 = TestOnlyModel.create(:name => 'first')
    obj2 = TestOnlyModelTwo.create(:arbitrary_name => 'second', :title => 'no_name')
    obj3 = TestOnlyModelTwo.create(:arbitrary_name => 'third', :title => 'no_name')

    obj1.test_only_model_two = obj2
    obj1.save

    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :type => :select)

    doc = HTML::Document.new(r)
    assert_select doc.root, 'select' do |lk|
      assert_select lk.first, 'option' do |opt|
        opt.each do |s_opt|
          assert_equal obj2.title, s_opt.children.first.content if s_opt['selected'].present?
        end
      end
    end
  end

  test "should_use_default_field_as_name" do
    obj1 = TestOnlyModelTwo.create(:title => 'first')
    obj2 = TestOnlyModel.create(:arbitrary_name => 'second', :name => 'no_name')
    obj3 = TestOnlyModel.create(:arbitrary_name => 'third', :name => 'no_name')

    obj1.test_only_model = obj2
    obj1.save

    r = relation_selector('test_only_model_two',
      :test_only_model,
      :object => obj1,
      :type => :select)

    doc = HTML::Document.new(r)
    assert_select doc.root, 'select' do |lk|
      assert_select lk.first, 'option' do |opt|
        opt.each do |s_opt|
          assert_equal obj2.name, s_opt.children.first.content if s_opt['selected'].present?
        end
      end
    end
  end

  test "should_use_additional_url_params" do
    obj1 = TestOnlyModel.create(:name => 'first')
    opts = {:param1 => 'is_one'}
    r = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :url_params => opts,
      :type => :autocomplete)

    assert_equal (r.index(ubiquo_test_only_model_twos_url({:format => 'js'}.merge(opts)))).present?, true

  end

  test "should_display_required_field_if_needed" do
    obj1 = TestOnlyModel.create(:name => 'first')
    opts = {:param1 => 'is_one'}
    r1 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :required => true,
      :type => :select)
    assert_equal r1.index('Test only model two *</label>').present?, true
    r2 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :type => :select)
    assert_equal r2.index('Test only model two</label>').present?, true

  end

  test "additional_options_display_if_needed" do
    obj1 = TestOnlyModel.create(:name => 'first')
    opts = {:param1 => 'is_one'}
    r1 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :type => :select)
    assert_equal r1.index('relation_new').present?, true
    r2 = relation_selector('test_only_model',
      :test_only_model_two,
      :object => obj1,
      :hide_controls => true,
      :type => :select)
    assert_equal r2.index('relation_new').present?, false
  end

  test "show description" do
    obj         = TestOnlyModel.create
    description = 'Description test'
    [ :select, :checkbox, :autocomplete ].each do |style|
      rs  = relation_selector( 'test_only_model',
                               :test_only_model_two,
                               :object      => obj,
                               :description => description,
                               :type        => style )

      doc = HTML::Document.new( content_tag( :body, rs, :class => 'body-test' ) )
      assert_select doc.root, 'body' do
        assert_select 'p.description', description
      end
    end
  end

  private

  def new_ubiquo_test_only_model_url options = {}
    return url_former('a/fake/url', options)
  end

  def ubiquo_test_only_models_url options = {}
    return url_former('another/fake/url', options)
  end

  def new_ubiquo_test_only_model_two_url options = {}
    return url_former('another/one/fake/url', options)
  end

  def ubiquo_test_only_model_twos_url options = {}
    return url_former('yet/another/one/fake/url', options)
  end

  def url_former name, options = {}
    return "#{name}?#{options.map{|lk| "#{lk.first.to_s}=#{lk.last}"}.join('&')}"
  end

  # Creates a parent TestOnlyModel with two TestOnlyModelTwo and another non-related
  # TestOnlyModelTwo. Returns the TestOnlyModel
  def prepare_relation_selector_instances
    parent = TestOnlyModel.create(:name => 'parent')
    TestOnlyModelTwo.create(:title => 'unassociated')

    parent.test_only_model_twos.concat(
      TestOnlyModelTwo.create(:title => 'child_one'),
      TestOnlyModelTwo.create(:title  => 'child_two')
    )
    parent
  end
end
