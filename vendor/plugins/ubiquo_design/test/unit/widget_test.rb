require File.dirname(__FILE__) + "/../test_helper.rb"

class WidgetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_widget
    assert_difference "Widget.count" do
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Widget.count" do
      widget = create_widget :name => ""
      assert widget.errors.on(:name)
    end
  end

  def test_should_require_block
    assert_no_difference "Widget.count" do
      widget = create_widget :block_id => nil
      assert widget.errors.on(:block)
    end
  end

  def test_should_auto_increment_position
    assert_difference "Widget.count", 2 do
      widget = create_widget :position => nil
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert_not_equal widget.position, nil
      position = widget.position
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert_equal widget.position, position+1
    end
  end

  def test_should_create_options_for_children
    assert_difference "Widget.count",2 do
      #CREATION
      widget = create_widget
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert widget.respond_to?(:title)
      assert widget.respond_to?(:description)

      #CREATION WITH OPTIONS
      widget = create_widget :title => "title", :description => "desc"
      assert !widget.new_record?, "#{widget.errors.full_messages.to_sentence}"
      assert widget.title === "title"
      assert widget.description === "desc"

      #FINDING
      widget = Widget.find(widget.id)
      assert widget.title === "title"
      assert widget.description === "desc"

      #MODIFY
      widget.title = "new title"
      assert widget.save
      assert Widget.find(widget.id).title === "new title"
    end
  end

  def test_should_set_is_modified_attribute_for_page_on_widget_update
    widget = widgets(:three)
    page = widget.block.page
    assert !page.reload.is_modified?
    assert widget.save
    assert page.reload.is_modified?
  end

  def test_should_set_is_modified_attribute_for_page_on_widget_delete
    widget = widgets(:three)
    page = widget.block.page
    assert !page.reload.is_modified?
    assert widget.destroy
    assert page.reload.is_modified?
  end

  def test_should_get_widget_key
    assert_equal :test_widget, TestWidget.new.key
  end

  def test_should_get_widget_class
    assert_equal TestWidget, Widget.class_by_key(:test_widget)
  end

  def test_should_return_widget_groups
    UbiquoDesign::Structure.define do
      widget_group :one do
        widget :one, :two
      end
      widget_group :two, :option => 'value' do
        widget :three, :four
      end
      widget :aa
    end
    assert_equal [:one, :two], Widget.groups[:one]
    assert_equal [:three, :four], Widget.groups[:two]
  end

  def test_delegated_page_method
    widget = create_widget
    assert_equal widget.block.page, widget.page
  end

  private
  def create_widget(options = {})
    TestWidget.create({:name => "Test Widget", :block_id => blocks(:one).id}.merge!(options))
  end
end
