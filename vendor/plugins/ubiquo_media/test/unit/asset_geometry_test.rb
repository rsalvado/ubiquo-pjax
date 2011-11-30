require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetGeometryTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_asset_geometry
    assert_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry
      assert !asset_geometry.new_record?, "#{asset_geometry.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_asset_id
    assert_no_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry(:asset_id => nil)
      assert asset_geometry.errors.on(:asset_id)
    end
  end

  def test_should_require_width
    assert_no_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry(:width=> nil)
      assert asset_geometry.errors.on(:width)
    end
  end

  def test_should_require_height
    assert_no_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry(:height=> nil)
      assert asset_geometry.errors.on(:height)
    end
  end

  def test_should_require_style
    assert_no_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry(:style=> nil)
      assert asset_geometry.errors.on(:style)
    end
  end

  def test_should_have_unique_style_for_the_same_asset
    first_geometry = create_asset_geometry(:style => 'unique')

    assert_no_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry(:style    => 'unique',
                                             :asset_id => first_geometry.asset_id)
      assert asset_geometry.errors.on(:style)
      asset_geometry = create_asset_geometry(:style    => 'UNIQUE',
                                             :asset_id => first_geometry.asset_id)
      assert asset_geometry.errors.on(:style)
    end

    assert_difference "AssetGeometry.count" do
      asset_geometry = create_asset_geometry(:style => 'unique',
                                             :asset => assets(:other))
      assert !asset_geometry.errors.on(:style)
    end
  end

  def test_should_get_data_from_file
    style = 'sample'
    asset_geometry = AssetGeometry.from_file(sample_image, style)

    # sample is a 60x60 image
    assert_equal 60, asset_geometry.height
    assert_equal 60, asset_geometry.width
    assert_equal style, asset_geometry.style
  end

  def test_should_generate_the_geometry
    style = 'sample'
    asset_geometry = AssetGeometry.from_file(sample_image, style)

    geometry = asset_geometry.generate
    assert_instance_of Paperclip::Geometry, geometry
    assert_equal asset_geometry.height, geometry.height
    assert_equal asset_geometry.width, geometry.width
  end

  private

  def create_asset_geometry(options = {})
    default_options = {
      :asset => assets(:image),
      :style => "original",
      :width => 1,
      :height => 1,
    }

    a = AssetGeometry.create(default_options.merge(options))
  end
end
