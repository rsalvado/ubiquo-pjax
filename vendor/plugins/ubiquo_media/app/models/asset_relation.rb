class AssetRelation < ActiveRecord::Base
  belongs_to :asset, :class_name => "Asset"
  belongs_to :related_object, :polymorphic => true

  validates_presence_of :asset

  before_create :set_position_and_name

  # Return the name (used for foot-text of images, for example) for a given asset and field
  def self.name_for_asset(field, asset, related_object)
    asset = Asset.gfind(asset)
    ar = self.find(:first, :conditions => {:field_name => field.to_s, :asset_id => asset.id, :related_object_type => related_object.class.base_class.to_s, :related_object_id => related_object.id})
    return asset.name if ar.nil?
    ar.name
  end

  private

  # Ensures the position and name fields is filled
  def set_position_and_name
    if related_object
      set_asset_name     unless self.name
      set_lower_position unless self.position
    else
      # related_object is validated here due to how nested_attributes work
      errors.add(:related_object, :blank)
      false
    end
  end

  # sets the name of the relation to the asset name
  def set_asset_name
    write_attribute :name, asset.name
  end

  # sets the max position to this element
  def set_lower_position
    write_attribute :position, related_object.send("#{field_name}_asset_relations").map(&:position).compact.max.to_i + 1
  end

end
