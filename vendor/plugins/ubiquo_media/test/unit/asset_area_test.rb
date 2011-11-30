require File.dirname(__FILE__) + "/../test_helper.rb"

class AssetAreaTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  def test_should_create_asset_area
    assert_difference "AssetArea.count" do
      asset_area = create_asset_area
      assert !asset_area.new_record?, "#{asset_area.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_asset_id
    assert_no_difference "AssetArea.count" do
      asset_area = create_asset_area(:asset_id => nil)
      assert asset_area.errors.on(:asset_id)
    end
  end

  def test_should_require_top
    assert_no_difference "AssetArea.count" do
      asset_area = create_asset_area(:top=> nil)
      assert asset_area.errors.on(:top)
    end
  end

  def test_should_require_left
    assert_no_difference "AssetArea.count" do
      asset_area = create_asset_area(:left=> nil)
      assert asset_area.errors.on(:left)
    end
  end

  def test_should_require_width
    assert_no_difference "AssetArea.count" do
      asset_area = create_asset_area(:width=> nil)
      assert asset_area.errors.on(:width)
    end
  end

  def test_should_require_height
    assert_no_difference "AssetArea.count" do
      asset_area = create_asset_area(:height=> nil)
      assert asset_area.errors.on(:height)
    end
  end

  def test_original_crop
    params = HashWithIndifferentAccess.new(
      :asset => assets(:image),
      :width => 1,
      :height => 2,
      :top => 3,
      :left => 4,
      :style => "original"
    )
    AssetArea.expects(:new).with( params ).returns(
      stub(:save! => true,:apply_original_crop! => true, :new_record? => true )
    )
    AssetArea.original_crop!( params )
  end

  # TODO: test apply_original_crop. It doesn't look easy at all.

  def test_from_format_sharp_horiz
    asset = assets(:image)
    AssetArea.any_instance.stubs(:original_geometry).returns(
      Paperclip::Geometry.parse("1000x1000"))
    aa = AssetArea.from_format( "100x50#", asset )
    assert_equal [250,0], [aa.top,aa.left]
    assert_equal [1000,500], [aa.width,aa.height]
  end

  def test_from_format_sharp_vertical
    asset = assets(:image)
    AssetArea.any_instance.stubs(:original_geometry).returns(
      Paperclip::Geometry.parse("1000x1000"))
    aa = AssetArea.from_format( "50x100#", asset )
    assert_equal [0, 250], [aa.top,aa.left]
    assert_equal [500,1000], [aa.width,aa.height]
  end

  def test_from_format_sharp_format_is_bigger
    asset = assets(:image)
    AssetArea.any_instance.stubs(:original_geometry).returns(
      Paperclip::Geometry.parse("30x30"))
    aa = AssetArea.from_format( "50x100#", asset )
    assert_equal [0, 7], [aa.top,aa.left]
    assert_equal [15,30], [aa.width,aa.height]
  end

  private
    
  def create_asset_area(options = {})
    default_options = {
      :asset => assets(:image),
      :style => "original",
      :width => 1,
      :height => 1,
      :top => 0,
      :left => 0
    }
    a = AssetArea.create(default_options.merge(options))
  end
  
end
