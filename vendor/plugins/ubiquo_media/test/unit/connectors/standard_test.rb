require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::StandardTest < ActiveSupport::TestCase

  Standard = UbiquoMedia::Connectors::Standard

  def setup
    save_current_connector(:ubiquo_media)
    Standard.load!
  end

  def teardown
    reload_old_connector(:ubiquo_media)
  end


  test 'uhook_create_assets_table_should_create_table' do
    ActiveRecord::Migration.expects(:create_table).with(:assets)
    ActiveRecord::Migration.uhook_create_assets_table {}
  end

  test 'uhook_create_asset_relations_table_should_create_table' do
    ActiveRecord::Migration.expects(:create_table).with(:asset_relations)
    ActiveRecord::Migration.uhook_create_asset_relations_table {}
  end

  test 'uhook_filtered_search_in_asset_should_yield' do
    Asset.expects(:all)
    Asset.uhook_filtered_search { Asset.all }
  end

  test 'uhook_after_update in asset should continue' do
    assert_not_equal false, Asset.new.uhook_after_update
  end

  test 'uhook_filtered_search_in_asset_relations_should_yield' do
    AssetRelation.expects(:all)
    AssetRelation.uhook_filtered_search { AssetRelation.all }
  end

  test 'uhook_index_filters_should_return_empty_hash' do
    assert_equal({}, Ubiquo::AssetsController.new.uhook_index_filters)
  end

  test 'uhook_index_search_subject should return asset class' do
    assert_equal Asset, Ubiquo::AssetsController.new.uhook_index_search_subject
  end

  test 'uhook_new_asset_should_return_new_asset' do
    asset = Ubiquo::AssetsController.new.uhook_new_asset
    assert asset.is_a?(AssetPublic)
    assert asset.new_record?
  end

  test 'uhook_edit_asset should return true' do
    assert Ubiquo::AssetsController.new.uhook_edit_asset(Asset.new)
  end

  test 'uhook_create_asset_should_return_new_asset' do
    mock_asset_params
    %w{AssetPublic AssetPrivate}.each do |visibility|
      asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
      assert_equal visibility, asset.class.to_s
      assert asset.new_record?
    end
  end

  test 'uhook_destroy_asset_should_destroy_asset' do
    Asset.any_instance.expects(:destroy).returns(:value)
    assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
  end

  test 'uhook_asset_filters_return_nil' do
    filter_set = mock()
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_filters
    end
    assert_nil Standard::UbiquoAssetsController::Helper.uhook_asset_filters(filter_set)
  end

  test 'uhook_edit_asset_sidebar_should_return_empty_string' do
    mock_media_helper
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_edit_asset_sidebar
    end
    assert_equal '', Standard::UbiquoAssetsController::Helper.uhook_edit_asset_sidebar(Asset.new)
  end

  test 'uhook_new_asset_sidebar should return empty string' do
    mock_media_helper
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_new_asset_sidebar
    end
    assert_equal '', Standard::UbiquoAssetsController::Helper.uhook_new_asset_sidebar(Asset.new)
  end

  test 'uhook_asset_index_actions should return array with edit and remove' do
    mock_media_helper
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_index_actions
    end

    # expectations to mock
    Standard::UbiquoAssetsController::Helper.expects(:t).at_least_once
    Standard::UbiquoAssetsController::Helper.expects(:link_to).twice

    actions = Standard::UbiquoAssetsController::Helper.uhook_asset_index_actions Asset.new
    assert actions.is_a?(Array)
    assert_equal 2, actions.size
  end

  test 'uhook_asset_form should return empty string' do
    mock_media_helper
    f = stub_everything
    Standard::UbiquoAssetsController::Helper.module_eval do
      module_function :uhook_asset_form
    end
    assert_equal '', Standard::UbiquoAssetsController::Helper.uhook_asset_form(f)
  end

  test 'uhook_media_attachment should register call' do
    AssetType.uhook_media_attachment :simple, {}
    assert Standard::get_uhook_calls(:uhook_media_attachment).flatten.detect { |call|
      call == {:klass => AssetType, :field => :simple, :options => {}}
    }
  end

end
