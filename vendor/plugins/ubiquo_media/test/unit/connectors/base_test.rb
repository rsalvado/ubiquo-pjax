require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::BaseTest < ActiveSupport::TestCase

  Base = UbiquoMedia::Connectors::Base

  test 'should_load_correct_modules' do
    ::Asset.expects(:include).with(Base::Asset)
    ::AssetRelation.expects(:include).with(Base::AssetRelation)
    ::Ubiquo::AssetsController.expects(:include).with(Base::UbiquoAssetsController)
    ::ActiveRecord::Migration.expects(:include).with(Base::Migration)
    ::ActiveRecord::Base.expects(:include).with(Base::ActiveRecord::Base)
    Base.expects(:set_current_connector).with(Base)
    Base.load!
  end

  test 'should_set_current_connector_on_load' do
    save_current_connector(:ubiquo_media)
    Base.load!
    assert_equal Base, Base.current_connector
    reload_old_connector(:ubiquo_media)
  end

  test_each_connector(:ubiquo_media) do

    test "uhook_create_assets_table_should_create_table" do
      ActiveRecord::Migration.expects(:create_table).with(:assets, anything)
      ActiveRecord::Migration.uhook_create_assets_table {}
    end

    test 'uhook_create_asset_relations_table_should_create_table' do
      ActiveRecord::Migration.expects(:create_table).with(:asset_relations, anything)
      ActiveRecord::Migration.uhook_create_asset_relations_table {}
    end

    test 'uhook_filtered_search_in_asset_should_yield' do
      Asset.expects(:all)
      Asset.uhook_filtered_search { Asset.all }
    end

    test 'uhook_after_update in asset should continue' do
      assert_not_equal false, AssetPublic.new.uhook_after_update
    end

    test 'uhook_filtered_search_in_asset_relations_should_yield' do
      AssetRelation.expects(:all)
      AssetRelation.uhook_filtered_search { AssetRelation.all }
    end

    test 'uhook_index_filters_should_return_hash' do
      mock_assets_controller
      assert Ubiquo::AssetsController.new.uhook_index_filters.is_a?(Hash)
    end

    test 'uhook_index_search_subject should return searchable' do
      mock_assets_controller
      assert_nothing_raised do
        Ubiquo::AssetsController.new.uhook_index_search_subject.filtered_search
      end
    end

    test 'uhook_new_asset_should_return_new_asset' do
      mock_assets_controller
      asset = Ubiquo::AssetsController.new.uhook_new_asset
      assert asset.is_a?(Asset)
      assert asset.new_record?
    end

    test 'uhook_edit_asset should not break' do
      mock_assets_controller
      assert_nothing_raised do
        Ubiquo::AssetsController.new.uhook_edit_asset Asset.new
      end
    end

    test 'uhook_create_asset_should_return_new_asset' do
      mock_assets_controller
      %w{AssetPublic AssetPrivate}.each do |visibility|
        asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
        assert_equal visibility, asset.class.to_s
        assert asset.new_record?
      end
    end

    test 'uhook_destroy_asset_should_destroy_asset' do
      mock_assets_controller
      Asset.any_instance.expects(:destroy).returns(:value)
      assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
    end

    test 'uhook_asset_filters_exist' do
      Base.current_connector::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_filters
      end
      assert_respond_to Base.current_connector::UbiquoAssetsController::Helper, :uhook_asset_filters
    end

    test 'uhook_edit_asset_sidebar_should_return_string' do
      mock_media_helper
      Base.current_connector::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_edit_asset_sidebar
      end
      assert Base.current_connector::UbiquoAssetsController::Helper.uhook_edit_asset_sidebar(Asset.new).is_a?(String)
    end

    test 'uhook_new_asset_sidebar should return string' do
      mock_media_helper
      Base.current_connector::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_new_asset_sidebar
      end
      assert Base.current_connector::UbiquoAssetsController::Helper.uhook_new_asset_sidebar(Asset.new).is_a?(String)
    end

    test 'uhook_asset_index_actions should return array' do
      mock_media_helper
      Base.current_connector::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_index_actions
      end
      assert Base.current_connector::UbiquoAssetsController::Helper.uhook_asset_index_actions(Asset.new).is_a?(Array)
    end

    test 'uhook_asset_form should return string' do
      mock_media_helper
      f = stub_everything
      f.stub_default_value = ''
      Base.current_connector::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_form
      end
      assert Base.current_connector::UbiquoAssetsController::Helper.uhook_asset_form(f).is_a?(String)
    end

    test 'uhook_media_attachment should register call' do
      AssetType.uhook_media_attachment :simple, {}
      assert Base::get_uhook_calls(:uhook_media_attachment).flatten.detect { |call|
        call == {:klass => AssetType, :field => :simple, :options => {}}
      }
    end

  end

  # Define module mocks for testing
  module Base::Asset; end
  module Base::AssetRelation; end
  module Base::UbiquoAssetsController; end
  module Base::Migration; end
  module Base::ActiveRecord
    module Base; end
  end

end
