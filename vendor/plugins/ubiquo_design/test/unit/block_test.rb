require File.dirname(__FILE__) + "/../../../../../test/test_helper.rb"

class BlockTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_block
    assert_difference "Block.count" do
      block = create_block
      assert !block.new_record?, "#{block.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_block_type
    assert_no_difference "Block.count" do
      block = create_block :block_type => nil
      assert block.errors.on(:block_type)
    end
  end

  def test_should_require_page_id
    assert_no_difference "Block.count" do
      block = create_block :page_id => nil
      assert block.errors.on(:page)
    end
  end

  def test_should_return_block_uses
    shared_block = blocks(:one)
    delegated_block = create_block(:shared_id => shared_block.id)
    delegated_block2 = create_block(:shared_id => shared_block.id)
    assert_equal_set [delegated_block, delegated_block2], shared_block.block_uses
  end

  def test_should_return_shared_block
    shared_block = blocks(:one)
    delegated_block = create_block(:shared_id => shared_block.id)
    assert_equal shared_block, delegated_block.shared
  end

  def test_shared_block_must_be_shared
    shared_block = blocks(:one)
    delegated_block = create_block(:shared_id => shared_block.id)
    assert shared_block.is_used_by_other_blocks?
  end

  def test_shouldnt_be_shared_delegated_block
    shared_block = blocks(:one)
    delegated_block = create_block(:shared_id => shared_block.id)
    assert !delegated_block.is_used_by_other_blocks?
  end

  def test_create_for_block_type_and_page
    assert_difference "Block.count" do
      block = Block.create_for_block_type_and_page("static", pages(:one))
      assert_equal block.page, pages(:one)
      assert_equal block.block_type, "static"
    end
  end

  def test_should_set_is_modified_attribute_for_page_on_block_update
    page = pages(:one_design)
    block = Block.create_for_block_type_and_page("static", page)
    assert page.reload.is_modified?
    page.publish
    assert !page.reload.is_modified?
    assert block.save
    assert page.reload.is_modified?
  end

  def test_should_set_is_modified_attribute_for_page_on_block_delete
    page = pages(:one_design)
    block = Block.create_for_block_type_and_page("static", page)
    assert page.reload.is_modified?
    page.publish
    assert !page.reload.is_modified?
    assert block.destroy
    assert page.reload.is_modified?
  end

  def test_should_not_break_is_modified_attribute_on_page_delete
    page = pages(:one_design)
    block = Block.create_for_block_type_and_page("static", page)
    page.destroy
    assert_nothing_raised {block.destroy}
  end

  def test_should_return_available_shared_blocks
    page = pages(:one_design)
    block = Block.create_for_block_type_and_page("sidebar", page, :is_shared => true)
    block2 = Block.create_for_block_type_and_page("sidebar", page, :is_shared => true)
    block3 = Block.create_for_block_type_and_page("main", page, :is_shared => true)

    uses_block = Block.new(:block_type => "sidebar", :is_shared => false)
    assert_equal_set [block, block2], uses_block.available_shared_blocks
  end

  def test_should_return_real_block
    block_to_share = create_block(:is_shared => true)
    using_share_block = create_block(:shared_id => block_to_share.id)
    assert_equal block_to_share, block_to_share.real_block
    assert_equal block_to_share, using_share_block.real_block
  end

  def test_should_return_available_widgets
    block = blocks(:one)
    available_widgets = UbiquoDesign::Structure.get(
      :page_template => block.page.page_template,
      :block => block.block_type
    )[:widgets].map(&:keys).flatten
    assert_equal available_widgets, block.available_widgets
  end

  private

  def create_block(options = {})
    default_options = {
      :block_type => 'sidebar',
      :page_id => pages(:one).id,
    }
    Block.create(default_options.merge!(options))
  end
end
