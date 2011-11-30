module Paperclip
  # Resizes an image to the :resize defined format, and then crops from the center
  # to achieve a geometry of :crop
  # Note that the :crop processor option does not need the trailing '#'
  class ResizeAndCrop < Thumbnail

    class InstanceNotGiven < ArgumentError; end

    attr_accessor :as_parent, :style

    def initialize(file, options = {}, attachment = nil)
      super
      @attachment = attachment
      self.style = options[:style_name] if options[:style_name].present?
      self.as_parent = true
      if( options[:crop_to] || self.asset_area )
        self.as_parent = false
        @crop_to = options[:crop_to] || (asset_area && asset_area.crop_to )
      end
    end

    # Overwritting the thumb methods
    def transformation_command
      return super if as_parent

      # We get the super and add methods to them
      trans = ""
      trans << " -crop \"#{@crop_to}\" +repage " if @crop_to
      trans
    end

    def make
      return super if as_parent
      # First we crop
      file = super
      # After allow to apply the format.
      Thumbnail.new( file, options, @attachment).make
    end

    protected

    def asset_area
      if style
        @asset_area ||= @attachment.instance.asset_areas.find_by_style(style.to_s)
      end
    end
  end
end
