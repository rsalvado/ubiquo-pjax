require "fileutils"

# An AssetArea is the area that is used to crop/resize a style of an asset
class AssetArea < ActiveRecord::Base

  belongs_to :asset

  validates_presence_of :asset_id, :top, :left, :width, :height, :style
  validates_numericality_of :top,:left,:width,:height,
    :only_integer => false, :greater_than => -1
  validates_numericality_of :width,:height, :greater_than => 0

   # Gives a string expressing the resize in a format ready for Paperclip::Gemometry#
  def resize_to
    "#{width}x#{height}!"
  end

  def crop_to
    "#{width}x#{height}+#{left}+#{top}"
  end

  # This method must be used only for :original image before calling the
  # Paperclip::Attachment#reprocess!

  def original_geometry
    asset.geometry
  end

  # Creates the special AssetArea to do the crop of the original image
  def self.original_crop! params
    asset_area = self.new( params )
    asset_area.save!
    asset_area.send(:apply_original_crop!)
  ensure
    #Make sure you destroy the element.
    asset_area.destroy unless !asset_area || asset_area.new_record?
  end

  # Based on the format it deduces the area that has been cropped
  # Used when there is no Asset area and the format has been already cropped
  # by ImageMagick
  def self.from_format  format, asset = nil
    obj = self.new
    obj.asset = asset if asset
    orig_geo = obj.original_geometry
    geo = Paperclip::Geometry.parse( format )
    return obj unless geo
    case geo.modifier
    when "#"
      if geo.aspect > orig_geo.aspect
        #Format is wider than original -> X wins
        obj.width = orig_geo.width
        obj.height = (orig_geo.width / geo.aspect).to_i
      else
        # Format is more vertical than original -> Y wins
        obj.height = orig_geo.height
        obj.width = (orig_geo.height * geo.aspect).to_i
      end
      obj.top = [0, (orig_geo.height - obj.height)/2].max
      obj.left = [0, (orig_geo.width - obj.width)/2].max
    end

    obj
  end

  protected
  # Applies the params of itself to
  def apply_original_crop!
    raise t(:original_crop_not_applyable) unless self.style == "original" && self.valid?
    #destroy all other assets as the crop areas will be outdated now
    self.asset.asset_areas.destroy_all

    img = Paperclip::ResizeAndCrop.new(
      self.asset.resource_file,
      { :convert_options => "", :geometry => resize_to, :crop_to => crop_to },
      self.asset.resource
    ).make

    # keep original to be able to recover it
    self.asset.backup

    # keep original name for the file
    resource_original_name = File.join(File.dirname(img.path),
                                       self.asset.resource_file_name)
    File.rename(img.path, resource_original_name)

    #Replace with current original
    self.asset.resource = File.open(resource_original_name)

    # Now we execute the regeneration of the styles again
    self.asset.resource.reprocess!
    self.asset.touch
  end


end
