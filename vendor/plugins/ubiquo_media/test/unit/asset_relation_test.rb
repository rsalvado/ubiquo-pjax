require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetRelationTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  def test_should_create_asset_relation
    assert_difference "AssetRelation.count" do
      asset_relation = create_asset_relation
      assert !asset_relation.new_record?, "#{asset_relation.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_asset
    assert_no_difference "AssetRelation.count" do
      asset_relation = create_asset_relation :asset_id => nil
      assert asset_relation.errors.on(:asset)
    end
  end

  def test_should_require_related_object_id
    assert_no_difference "AssetRelation.count" do
      asset_relation = create_asset_relation :related_object_id => nil
      assert asset_relation.errors.on(:related_object)
    end
  end

  def test_should_require_related_object_type
    assert_no_difference "AssetRelation.count" do
      asset_relation = create_asset_relation :related_object_type => nil
      assert asset_relation.errors.on(:related_object)
    end
  end

  def test_should_require_valid_related_object_type
    assert_no_difference "AssetRelation.count" do
      assert_raise NameError do
        asset_relation = create_asset_relation :related_object_type => "HelloWorldClass"
      end
    end
  end

  def test_should_require_valid_related_object_values
    related_class = "UbiquoUser"
    related_id = UbiquoUser.maximum(:id) + 1
    assert_no_difference "AssetRelation.count" do
      asset_relation = create_asset_relation :related_object_id => related_id, :related_object_type => related_class
      assert asset_relation.errors.on(:related_object)
    end
  end
  
  private

  def create_asset_relation(options = {})
    AssetRelation.create({
      :asset_id => assets(:video).id,
      :related_object_id => ubiquo_users(:josep).id,
      :related_object_type => 'UbiquoUser',
      :position => 1
    }.merge(options))
  end
end
