require "fileutils"

# An asset is a resource with name, description and one associated
# file.
#
# This model has no associated file right away. The sublcasses AssetPublic and
# AssetProtected have the attribute :resource as a file_attachment and so they
# are the models to work with.
class Asset < ActiveRecord::Base
  BACKUP_EXTENSION = ".bak" # Extension to copy the backup
  belongs_to :asset_type

  has_many :asset_relations, :dependent => :destroy
  has_many :asset_areas, :dependent => :destroy
  has_many :asset_geometries, :dependent => :destroy

  validates_presence_of :name, :asset_type_id, :type
  before_validation_on_create :set_asset_type
  after_update :uhook_after_update
  attr_accessor :cloned_from
  after_create :save_backup_on_clone
  after_save :update_backup
  after_save :save_geometries

  # Generic find (ID, key or record)
  def self.gfind(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_name(something.to_s, options)
    when Asset
      something
    else
      nil
    end
  end

  # filters:

  #   :type: ID of AssetType separated by commas
  #   :text: String to search in asset name and description
  #
  # options: find_options
  def self.filtered_search(filters = {}, options = {})
    filter_type = if filters[:type]
      types_id = filters[:type].to_s.split(",").map(&:to_i)
      {:find => {:conditions => ["assets.asset_type_id IN (?)", types_id]}}
    else {}
    end
    filter_text = unless filters[:text].blank?
      args = ["%#{filters[:text]}%"] * 2
      condition = "upper(assets.name) LIKE upper(?) OR upper(assets.description) LIKE upper(?)"
      {:find => {:conditions => [condition] + args}}
    else {}
    end
    filter_visibility = unless filters[:visibility].blank?
      {:find => {:conditions => ["assets.type = ?", "asset_#{filters[:visibility]}".classify]}}
    else {}
    end
    filter_create_start = if filters[:created_start]
      {:find => {:conditions => ["assets.created_at >= ?", filters[:created_start]]}}
    else {}
    end
    filter_create_end = if filters[:created_end]
      {:find => {:conditions => ["assets.created_at <= ?", filters[:created_end]]}}
    else {}
    end

    uhook_filtered_search(filters) do
      with_scope(filter_text) do
        with_scope(filter_type) do
          with_scope(filter_visibility) do
            with_scope(filter_create_start) do
              with_scope(filter_create_end) do
                with_scope(:find => options) do
                  Asset.find(:all)
                end
              end
            end
          end
        end
      end
    end
  end

  def self.visibilize(visibility)
    "asset_#{visibility}".classify.constantize
  end

  # Correct parameters to the resize_and_crop processor.
  # If the processor is other, the extra params will be ignored
  def self.correct_styles(styles_list = {})
    global_options = Ubiquo::Config.context(:ubiquo_media).get(:media_styles_options)

    styles_list.map do |style, value|
      extra_options = global_options.is_a?(Proc) ? global_options.call(style, value) : global_options
      [style, {:geometry => value, :style_name => style}.merge(extra_options)]
    end.to_hash
  end

  def is_resizeable?
    self.asset_type && self.asset_type.key == "image" && self.resource
  end

  def backup_path
    self.resource.path + BACKUP_EXTENSION
  end

  # Backups the original file if backup does not exist
  def backup
    self.keep_backup && !File.exists?( backup_path ) && FileUtils.cp( self.resource.path, backup_path )
  end

  # Restores the backuped file. Returns true when restored successfully
  def restore!
    if restorable?
      FileUtils.mv backup_path, self.resource.path
      self.asset_areas.destroy_all
      self.resource.reprocess!
      true
    end
  end

  def restorable?
    File.exists? backup_path
  end

  # clone the asset (not the related models) and the resource
  def clone
    obj                    = super
    obj.resource           = self.resource_file
    obj.resource_file_name = self.resource_file_name
    obj.cloned_from        = self
    uhook_cloned_object( obj )

    obj
  end

  def clone?
    self.cloned_from ? true : false
  end

  def geometry(style = :original)
    asset_geometry = self.asset_geometries.find_by_style(style.to_s)

    unless asset_geometry
      asset_geometry = calculate_geometry(style)
      if asset_geometry
        asset_geometry.asset_id = self.id
        asset_geometry.save
      end
    end

    asset_geometry.generate if asset_geometry
  end

  def keep_backup
    # keep backups only in filesystem
    return false unless self.resource.options[:storage] == :filesystem

    self[:keep_backup]
  end

  def resource_file(style = :original)
    if self.resource
      return self.resource.to_file(style) if self.resource.options[:storage] == :filesystem

      @tmp_files ||= {}
      @tmp_files[style] ||= self.resource.to_file(style)
    end
  end

  private

  def set_asset_type
    if self.resource_file_name && self.resource.errors.blank?
      # mime_types hash is here momentarily but maybe its must be in ubiquo config
      mime_types = Ubiquo::Config.context(:ubiquo_media).get(:mime_types)
      content_type = self.resource_content_type.split('/') rescue []
      mime_types.each do |type_relations|
        type_relations.last.each do |mime|
          if content_type.include?(mime)
            self.asset_type = AssetType.find_by_key(type_relations.first.to_s)
          end
        end
      end
      self.asset_type = AssetType.find_by_key("other") unless self.asset_type
    end
  end

  # Keeps the backup file when an asset has been cloned
  def save_backup_on_clone
    if self.cloned_from && self.cloned_from.restorable? && self.keep_backup
      FileUtils.mkdir_p( File.dirname( self.backup_path ))
      FileUtils.cp( self.cloned_from.backup_path, self.backup_path )
    end
  end

  def update_backup
    unless self.keep_backup
      # Delete backup
      File.unlink( self.backup_path ) if File.exists?( self.backup_path )
    end
  end

  def generate_geometries
    self.asset_geometries.destroy_all

    unless self.clone?
      @asset_geometries_to_save = []

      if self.resource && self.resource_content_type.include?('image')
        self.resource.styles.map { |s| s.first }.each do |style|
          @asset_geometries_to_save << calculate_geometry(style)
        end
        @asset_geometries_to_save << calculate_geometry
      end
    end
  end

  def save_geometries
    unless self.clone?
      @asset_geometries_to_save ||= []

      self.asset_geometries.destroy_all unless @asset_geometries_to_save.empty?
      @asset_geometries_to_save.each do |asset_geometry|
        asset_geometry.asset_id = self.id
        asset_geometry.save
      end
    end
  end

  def calculate_geometry(style = :original)
    AssetGeometry.from_file(self.resource_file(style), style)
  end

  def clean_tmp_files
    @tmp_files = nil
  end

end
