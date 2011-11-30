require File.dirname(__FILE__) + "/../test_helper.rb"

class MediaFileTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_simple
    item = AssetType.first
    asset = Asset.first

    assert !item.simple.is_full?
    assert_difference "::AssetRelation.count" do
      assert_difference "item.simple.size" do
        item.simple << asset
      end
    end

    assert item.simple.is_full?
  end

  def test_multiple
    item = AssetType.first
    asset_one = Asset.first

    assert !item.multiple.is_full?
    assert_difference "::AssetRelation.count" do
      assert_difference "item.multiple.size" do
        item.multiple << asset_one
      end
    end
    assert !item.multiple.is_full?
  end

  def test_sized
    item = AssetType.first
    asset_one, asset_two = two_assets
    assert asset_one != asset_two

    assert !item.sized.is_full?
    assert_difference "::AssetRelation.count",2 do
      assert_difference "item.sized.size",2 do
        item.sized << [asset_one,asset_two]
      end
    end
    assert item.sized.is_full?
  end

  def test_all_types
    t = AssetType.first
    a = assets(:video)
    assert t.all_types.accepts?(a)
    a = assets(:audio)
    assert t.all_types.accepts?(a)
  end

  def test_some_types
    t = AssetType.first
    a = assets(:video)
    assert t.some_types.accepts?(a)
    a = assets(:doc)
    assert !t.some_types.accepts?(a)
  end

  def test_insertion_of_asset_relations
    AssetRelation.destroy_all

    item = AssetType.first
    asset = Asset.first
    assert_difference "::AssetRelation.count" do
      assert_difference "item.simple.size" do
        item.simple << asset
      end
    end

    rel = AssetRelation.first
    assert rel.field_name == 'simple'
  end

  def test_insertion_on_save_and_create
    asset = Asset.first
    item = nil
    assert_no_difference "::AssetRelation.count" do
      item = AssetType.new :simple_ids => [asset.id.to_s]
    end

    assert_equal 1, item.simple.size

    assert_no_difference "item.simple.size" do
      assert_difference "::AssetRelation.count" do
        assert item.save
      end
    end
  end

  def test_named_relations
    asset_one, asset_two = two_assets
    item = nil
    assert_difference "::AssetRelation.count", 2 do
      item = AssetType.create :multiple_asset_relations_attributes => [
        {"asset_id" => asset_one.id.to_s, "name" => "Test name", :field_name => 'multiple'},
        {"asset_id" => asset_two.id.to_s, "name" => "Test name 2", :field_name => 'multiple'}
       ]
    end
    item.multiple.reload
    assert_equal item.name_for_asset(:multiple, item.multiple[0]), "Test name"
    assert_equal item.name_for_asset(:multiple, item.multiple[1]), "Test name 2"
  end

  def test_updating_by_named_relations
    # This is what happens when, in the browser workflow,
    # you change the name to an existing relation.
    asset_one, asset_two = two_assets
    item = AssetType.create :multiple_attributes => [
      {"asset_id" => asset_one.id.to_s, "name" => "Test name"},
      {"asset_id" => asset_two.id.to_s, "name" => "Test name 2"}
     ]
    relations = item.asset_relations
    assert_difference "::AssetRelation.count", 0 do
      item.update_attributes :multiple_attributes => {
        1 => {"asset_id" => asset_one.id.to_s, "name" => "Test name", 'position' => '1', "id" => relations.first.id.to_s},
        2 => {"asset_id" => asset_two.id.to_s, "name" => "New Test name", 'position' => '2', "id" => relations.last.id.to_s}
      }
    end
    assert_equal item.name_for_asset(:multiple, item.multiple[0]), "Test name"
    assert_equal item.name_for_asset(:multiple, item.multiple[1]), "New Test name"
  end

  def test_updating_by_named_relations_destroys_every_non_referenced_asset_relation
    # In the view, we simply don't send any to-be-destroyed association information,
    # and the model must know that any missing id will be fired.
    asset_one, asset_two = two_assets
    item = AssetType.create :multiple_attributes => [
      {"asset_id" => asset_one.id.to_s, "name" => "Test name"},
      {"asset_id" => asset_two.id.to_s, "name" => "Test name 2"}
     ]
    relations = item.asset_relations

    assert_difference "::AssetRelation.count", -1 do
      item.update_attributes :multiple_attributes => {
        2 => {"asset_id" => asset_two.id.to_s, "name" => "New Test name", 'position' => '2', "id" => relations.last.id.to_s}
      }
    end
    assert_equal item.name_for_asset(:multiple, item.multiple[0]), "New Test name"
    assert_equal [asset_two], item.multiple

    assert_difference "::AssetRelation.count", -1 do
      item.update_attributes :multiple_attributes => {}
    end
    assert_equal [], item.reload.multiple
    assert_equal [], item.multiple_asset_relations
  end

  def test_asset_relations_attribute_on_unsaved_instance
    # This is how controllers and media_selector use these fields
    # If this passes it means that media_selector will retain and display assets
    # when the related element has not been saved due to errors.
    asset_one, asset_two = two_assets
    item = nil
    assert_no_difference "::AssetRelation.count" do
      item = AssetType.new :multiple_attributes => [
        {"asset_id" => asset_one.id.to_s, "name" => "Test name"},
        {"asset_id" => asset_two.id.to_s, "name" => "Test name 2"}
      ]
    end
    assert_equal 2, item.multiple_asset_relations.size
    assert_equal ["Test name", "Test name 2"], item.multiple_asset_relations.map(&:name)
  end

  def test_array_of_ids
    asset = Asset.first
    item = nil
    assert_difference "::AssetRelation.count" do
      item = AssetType.create :simple_ids => [asset.id]
    end
    assert_equal item.simple.size, 1
  end

  def test_hashed_ids_with_positions
    asset_one, asset_two = two_assets
    item = nil
    assert_difference "::AssetRelation.count", 2 do
      item = AssetType.create :multiple_asset_relations_attributes => {
        '0.524' => {'asset_id' => asset_one.id.to_s, 'position' => '4', 'field_name' => 'multiple'},
        '0.425' => {'asset_id' => asset_two.id.to_s, 'position' => '5', 'field_name' => 'multiple'}
      }
    end
    assert_equal 2, item.multiple.size
    assert_equal_set [4,5], item.asset_relations.map(&:position)
    assert_equal asset_one, item.multiple.first
  end

  def test_relation_order_on_creation
    AssetRelation.delete_all
    asset_one, asset_two = two_assets
    assert_difference "::AssetRelation.count", 2 do
      AssetType.create :multiple_asset_relations_attributes => [
        {"asset_id" => asset_one.id.to_s, "name" => "Test name", "field_name" => 'multiple'},
        {"asset_id" => asset_two.id.to_s, "name" => "Test name 2", "field_name" => 'multiple'}
      ]
    end
    assert_equal 1, AssetRelation.first.position
    assert_equal 2, AssetRelation.first(:offset => 1).position
  end

  def test_relation_order_on_update
    AssetRelation.delete_all
    asset_one, asset_two = two_assets
    item = AssetType.create :multiple_attributes => two_asset_relation_attributes
    item.multiple = [asset_two, asset_one]

    assert_equal 2, asset_one.reload.asset_relations.first.position
    assert_equal "Relation to asset one", asset_one.reload.asset_relations.first.name
    assert_equal 1, asset_two.reload.asset_relations.first.position
    assert_equal "Relation to asset two", asset_two.reload.asset_relations.first.name
  end

  def test_does_not_create_new_relations_on_assignation
    # This kind of consistence is not required per se since for this plugin AssetRelation
    # is just an intermediate table, but ensuring it allows third parties to expand
    # this table if they need/want it.
    AssetRelation.delete_all
    asset_one, asset_two = two_assets
    item = AssetType.create :multiple_attributes => two_asset_relation_attributes
    original_ids = item.asset_relations.map(&:id)
    item.multiple = [asset_two, asset_one] # already there, just reassigning
    assert_equal_set original_ids, item.reload.asset_relations.map(&:id)
  end

  def test_alias_for_assigning_attributes_with_array
    asset_one, asset_two = two_assets
    item = AssetType.create :multiple_attributes => two_asset_relation_attributes
    assert_equal [asset_one, asset_two], item.reload.multiple
    assert_equal [], item.simple
  end

  def test_alias_for_assigning_attributes_with_hash
    asset_one = Asset.first
    item = AssetType.create
    asset_relations = { '1' => {"asset_id" => asset_one.id, "name" => "Relation to asset one" }}
    item.update_attributes :multiple_attributes => asset_relations
    assert_equal [asset_one], item.reload.multiple
    assert_equal [], item.simple
  end

  def test_name_for_asset_should_work_when_multiple_media_attachments_are_in_use
    asset = assets(:audio)
    item = AssetType.create :simple_ids => [asset.id]
    item.name_for_asset(:simple, asset)
    item.update_attributes :some_type_ids => [asset.id]
    item = AssetType.find(item.id)
    assert_equal [asset], item.some_types
  end

  def test_should_destroy_old_relations
    AssetRelation.destroy_all
    asset_one, asset_two = two_assets
    item = nil
    assert_difference "AssetRelation.count" do
      item = AssetType.create :simple_ids => [asset_one.id]
    end
    assert_no_difference "AssetRelation.count" do
      item.simple_ids = [asset_two.id]
      item.save
    end
  end

  def test_should_require_all_n_assets_if_true
    AssetRelation.destroy_all
    asset_one, asset_two = two_assets
    item = AssetType.new(:sized => [asset_one])
    item.sized.options[:required] = true

    begin
      assert !item.valid?
      assert item.errors.on(:sized)

      item.update_attributes :sized => [asset_one, asset_two]
      assert item.valid?
    ensure
      # cleanup
      item.sized.options[:required] = false
    end
  end

  # as above, but with the method that controllers will use
  def test_should_require_all_n_assets_if_true_using_attributes
    AssetRelation.destroy_all
    item = AssetType.new
    item.sized.options[:required] = true

    begin
      item.update_attributes :sized_attributes => two_asset_relation_attributes
      assert item.valid?
    ensure
      # cleanup
      item.sized.options[:required] = false
    end
  end

  def test_should_require_some_assets_if_provided_by_number
    AssetRelation.destroy_all
    asset_one = Asset.first
    item = AssetType.new
    item.sized.options[:required] = 1

    begin
      assert !item.valid?
      assert item.errors.on(:sized)

      item.update_attributes :sized => [asset_one]
      assert item.valid?
    ensure
      # cleanup
      item.sized.options[:required] = false
    end
  end

  # as above, but with the method that controllers will use
  def test_should_require_some_assets_if_provided_by_number_using_attributes
    AssetRelation.destroy_all
    item = AssetType.new
    item.sized.options[:required] = 1

    begin
      item.update_attributes :sized_attributes => [two_asset_relation_attributes.first]
      assert item.valid?
    ensure
      # cleanup
      item.sized.options[:required] = false
    end
  end

  def test_should_require_one_asset_if_true_and_size_many
    AssetRelation.destroy_all
    asset_one = Asset.first
    item = AssetType.new
    item.multiple.options[:required] = true

    begin
      assert !item.valid?
      assert item.errors.on(:multiple)

      item.update_attributes :multiple => [asset_one]
      assert item.valid?
    ensure
      # cleanup
      item.multiple.options[:required] = false
    end
  end

  # as above, but with the method that controllers will use
  def test_should_require_one_asset_if_true_and_size_many_with_attributes
    AssetRelation.destroy_all
    item = AssetType.new
    item.multiple.options[:required] = true

    begin
      item.update_attributes :multiple_attributes => [two_asset_relation_attributes.first]
      assert item.valid?
    ensure
      # cleanup
      item.multiple.options[:required] = false
    end
  end

  # the edge case with our implementation: field_asset_relations is empty but field isn't
  def test_should_require_one_asset_if_has_been_deleted_with_attributes
    AssetRelation.destroy_all
    item = AssetType.new
    item.multiple.options[:required] = true

    begin
      item.update_attributes :multiple_attributes => [two_asset_relation_attributes.first]
      assert 2, item.multiple.size
      assert item.valid?
      assert !item.update_attributes(:multiple_attributes => {})
    ensure
      # cleanup
      item.multiple.options[:required] = false
    end
  end

  # Test for the issue detected in #268
  def test_should_not_modify_config_when_defining_paperclip_styles
    styles_hash = {
        :style_name => {
          :processors => [:example_processor],
        }
    }

    # short way to recursivelly clone
    styles_hash_copy = Marshal.load(Marshal.dump(styles_hash))

    Ubiquo::Config.context(:ubiquo_media).set do |config|
      config.media_styles_list = styles_hash_copy
    end
    begin
      # Reload the AssetPublic class, that uses this defined option
      Object.send :remove_const, 'AssetPublic'
      require File.dirname(__FILE__) + '/../../app/models/asset_public'

      # this triggers the Style initialization, which uses the hash
      asset = AssetPublic.new
      asset.attachment_for(:resource).styles

      assert_equal styles_hash, Ubiquo::Config.context(:ubiquo_media).get(:media_styles_list)
      assert !styles_hash[:style_name].blank?
    ensure
      # cleanup
      AssetPublic.attachment_definitions[:resource] = AssetPrivate.attachment_definitions[:resource]
    end
  end

  protected

  def two_assets
    [Asset.first, Asset.first(:offset => 1)]
  end

  def two_asset_relation_attributes
    asset_one, asset_two = two_assets
    [
      {"asset_id" => asset_one.id, "name" => "Relation to asset one" },
      {"asset_id" => asset_two.id, "name" => "Relation to asset two" }
    ]
  end

end
