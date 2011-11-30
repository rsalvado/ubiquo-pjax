require File.dirname(__FILE__) + "/../test_helper.rb"

# Asset for tests
class AssetMock < Asset
  file_attachment :resource,
                  :visibility => "public",
                  :styles     => self.correct_styles({ :test => "20x20#",
                                                       :test2 => "15x15#" }),
                  :processors => [:resize_and_crop],
                  :storage    => :filesystem

  validates_attachment_presence :resource

  before_post_process :clean_tmp_files
  after_resource_post_process :generate_geometries
end

class AssetTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  def test_should_create_asset
    assert_difference "Asset.count" do
      asset = create_asset
      assert !asset.new_record?, "#{asset.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Asset.count" do
      asset = create_asset(:name => nil)
      assert asset.errors.on(:name)
    end
  end

  def test_should_require_resource
    assert_no_difference "Asset.count" do
      asset = create_asset(:resource => nil)
      assert asset.errors.on(:resource_file_name)
    end
  end

  def test_should_require_asset_type_id
    assert_no_difference "Asset.count" do
      #if asset hasn't resource, it can't set asset type
      asset = create_asset(:resource => nil)
      assert asset.errors.on(:asset_type_id)
    end
  end

  def test_simple_filter
    assets = Asset.filtered_search
    assert_equal assets.size, Asset.count
  end

  def test_filter_by_text_searching_case_insensitive_on_name_and_description
    Asset.delete_all
    asset1 = create_asset(:name => 'name1', :description => 'description1')
    asset2 = create_asset(:name => 'name2', :description => 'description2')
    assert_equal_set [asset1, asset2], Asset.filtered_search({:text => 'name'})
    assert_equal_set [asset1], Asset.filtered_search({:text => 'nAMe1'})
    assert_equal_set [asset2], Asset.filtered_search({:text => 'DESCRIPTION2'})
  end

  def test_filter_by_creation_date
    Asset.delete_all
    asset1 = create_asset(:created_at => 3.days.ago)
    asset2 = create_asset(:created_at => 1.days.from_now)
    asset3 = create_asset(:created_at => 10.days.from_now)
    assert_equal_set [asset2, asset3], Asset.filtered_search({:created_start => Time.now}, {})
    assert_equal_set [asset1], Asset.filtered_search({:created_end => Time.now}, {})
    assert_equal_set [asset1, asset2], Asset.filtered_search({:created_start => 5.days.ago, :created_end => 1.days.from_now}, {})
  end

  def test_should_be_stored_in_public_path
     asset = create_asset(:name => "FAKE")
    assert asset.resource.path =~ /#{File.join(Rails.root, Ubiquo::Config.get(:attachments)[:public_path])}/
  end

  def test_should_be_stored_in_protected_path
    asset = AssetPrivate.create(:name => "FAKE2",
                                :resource => test_file,
                                :asset_type_id => AssetType.find(:first).id)
    assert asset.resource.path =~ /#{File.join(Rails.root, Ubiquo::Config.get(:attachments)[:private_path])}/
  end

  def test_should_destroy_relations_on_destroy
    Asset.destroy_all
    AssetRelation.destroy_all

    asset = create_asset

    assert_difference("AssetRelation.count") do
      AssetRelation.create(:asset => asset, :related_object => AssetType.first, :field_name => 'simple')
    end
    assert_difference("AssetRelation.count", -1) do
      asset.destroy
    end
  end

  def test_should_destroy_asset_areas_on_destroy
    Asset.destroy_all
    AssetArea.destroy_all

    asset = create_asset

    assert_difference("AssetArea.count") do
      AssetArea.create!(:asset => asset, :style => "original", :top => 1, :left => 1, :width => 1, :height => 1)
    end
    assert_difference("AssetArea.count", -1) do
      asset.destroy
    end
  end

  def test_is_resizeable
    asset = create_asset
    assert !asset.is_resizeable?

    asset.asset_type = AssetType.find_by_key("image")
    assert asset.is_resizeable?
  end

  def test_should_generate_all_geometries_after_process_resource
    Asset.destroy_all
    AssetGeometry.destroy_all

    asset = create_asset(:resource   => sample_image,
                         :asset_type => AssetType.find_by_key("image"))

    # should add original style to style list
    assert_equal asset.resource.styles.count + 1, asset.asset_geometries.count
  end

  def test_should_get_geometries_by_style
    Asset.destroy_all
    AssetGeometry.destroy_all

    asset = create_asset(:resource   => sample_image,
                         :asset_type => AssetType.find_by_key("image"))
    asset.resource.styles.map { |s| s.first }.each do |style|
      assert_instance_of Paperclip::Geometry, asset.geometry(style)
    end
    assert_instance_of Paperclip::Geometry, asset.geometry # original case
  end

  def test_should_generate_geometry_if_dont_exist
    Asset.destroy_all
    AssetGeometry.destroy_all

    asset = create_asset(:resource   => sample_image,
                         :asset_type => AssetType.find_by_key("image"))

    AssetGeometry.destroy_all
    assert_instance_of Paperclip::Geometry, asset.geometry # original case
    assert_equal 1, asset.asset_geometries.count
  end

  def test_should_get_resource_file
    asset = create_asset(:resource => sample_image)

    assert File.identical?(asset.resource.to_file, asset.resource_file)
    assert File.identical?(asset.resource.to_file(:thumb), asset.resource_file(:thumb))
  end

  def test_should_change_styles_with_asset_areas
    Asset.destroy_all
    AssetArea.destroy_all

    asset = create_mock_asset(:resource => sample_image)
    assert_equal "20x20", Paperclip::Geometry.from_file(asset.resource_file(:test)).to_s
    assert_equal "15x15", Paperclip::Geometry.from_file(asset.resource_file(:test2)).to_s

    asset.asset_areas << AssetArea.new(:top    => 0,
                                       :left   => 0,
                                       :width  => 10,
                                       :height => 10,
                                       :style  => "test")
    asset.resource.reprocess!
    # the geometry shouldn't change
    assert_equal "20x20", Paperclip::Geometry.from_file(asset.resource_file(:test)).to_s
    assert_equal "15x15", Paperclip::Geometry.from_file(asset.resource_file(:test2)).to_s

    asset.asset_areas.find_by_style("test").update_attributes(:top    => 2,
                                                              :left   => 2,
                                                              :width  => 7,
                                                              :height => 7)
    asset.resource.reprocess!
    # the geometry shouldn't change
    assert_equal "20x20", Paperclip::Geometry.from_file(asset.resource_file(:test)).to_s
    assert_equal "15x15", Paperclip::Geometry.from_file(asset.resource_file(:test2)).to_s
  end

  test "should clone the asset resource" do
    a = create_mock_asset(:resource => sample_image)
    b = a.clone
    assert b.save, b.errors.full_messages.to_sentence
    assert_equal a.resource_file_name, b.resource_file_name
    assert_equal a.resource_file_size, b.resource_file_size
    assert_equal a.resource_content_type, b.resource_content_type
    assert_equal a.resource_file.read, b.resource_file.read
  end

  private

  def create_asset(options = {})
    default_options = {
      :name        => "Created asset",
      :description => "Description",
      :resource    => test_file,
    }
    a = AssetPublic.create(default_options.merge(options))
  end

  def create_mock_asset(options = {})
    default_options = {
      :name        => "Created asset",
      :description => "Description",
      :resource    => test_file,
    }
    a = AssetMock.create(default_options.merge(options))
  end

end
