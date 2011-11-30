# An AssetGeometry is the geometry for each style processed for an Asset
# It used to save all the geometries and do not calutate it later
class AssetGeometry < ActiveRecord::Base
  belongs_to :asset

  validates_presence_of :asset_id, :style, :width, :height
  validates_numericality_of :width, :height,
                            :only_integer => false,
                            :greater_than => 0
  validates_uniqueness_of :style, :scope => :asset_id, :case_sensitive => false

  def self.from_file(file, style = :original)
    if file
      geometry = Paperclip::Geometry.from_file(file)
      AssetGeometry.new(:width  => geometry.width,
                        :height => geometry.height,
                        :style  => style.to_s) if geometry
    end
  end

  def generate
    @geometry ||= Paperclip::Geometry.new(self.width, self.height)
  end
end
