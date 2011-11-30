require File.dirname(__FILE__) + "/../../test_helper"

class UbiquoMedia::Connectors::I18nTest < ActiveSupport::TestCase

  I18n = UbiquoMedia::Connectors::I18n

  if Ubiquo::Plugin.registered[:ubiquo_i18n]

    def setup
      save_current_connector(:ubiquo_media)
      I18n.load!
    end

    def teardown
      Locale.current = nil
      reload_old_connector(:ubiquo_media)
    end

    test 'Asset classes should be translatable' do
      [Asset, AssetPublic, AssetPrivate, AssetRelation].each do |klass|
        assert klass.is_translatable?, "#{klass} is not translatable"
      end
    end

    test 'uhook_create_assets_table_should_create_table_with_i18n_info' do
      ActiveRecord::Migration.expects(:create_table).with(:assets, :translatable => true)
      ActiveRecord::Migration.uhook_create_assets_table {}
    end

    test 'uhook_create_asset_relations_table_should_create_table' do
      ActiveRecord::Migration.expects(:create_table).with(:asset_relations, :translatable => true)
      ActiveRecord::Migration.uhook_create_asset_relations_table {}
    end

    test 'uhook_filtered_search_in_asset_should_yield_with_locale_filter' do
      Asset.expects(:all)
      Asset.expects(:with_scope).with(:find => {:conditions => ["assets.locale <= ?", 'ca']}).yields
      Asset.uhook_filtered_search({:locale => 'ca'}) { Asset.all }
    end

    test 'uhook_after_update in asset should update resource in translations' do
      asset_1 = AssetPublic.new(:locale => 'ca', :resource => 'one')
      asset_2 = AssetPublic.new(:locale => 'en')
      asset_1.expects(:translations).returns([asset_2])
      asset_2.expects(:resource=)
      asset_2.expects(:save)
      asset_1.uhook_after_update
    end

    test 'uhook_filtered_search_in_asset_relations_should_yield_with_locale_filter' do
      AssetRelation.expects(:all)
      AssetRelation.expects(:with_scope).with(:find => {:conditions => ["asset_relations.locale <= ?", 'ca']}).yields
      AssetRelation.uhook_filtered_search({:locale => 'ca'}) { AssetRelation.all }
    end

    test 'uhook_index_filters_should_return_locale_filter' do
      mock_asset_params :filter_locale => 'ca'
      assert_equal({:locale => 'ca'}, Ubiquo::AssetsController.new.uhook_index_filters)
    end

    test 'uhook_index_search_subject should return locale filtered assets' do
      Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      Asset.expects(:locale).with('ca', :all).returns(Asset)
      assert_nothing_raised do
        Ubiquo::AssetsController.new.uhook_index_search_subject.filtered_search
      end
    end

    test 'uhook_new_asset_should_return_translated_asset' do
      mock_asset_params :from => 1
      Ubiquo::AssetsController.any_instance.expects(:current_locale).returns('ca')
      AssetPublic.expects(:translate).with(1, 'ca', :copy_all => true)
      asset = Ubiquo::AssetsController.new.uhook_new_asset
    end

    test 'uhook_edit_asset should not return false if current locale' do
      Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      assert_not_equal false, Ubiquo::AssetsController.new.uhook_edit_asset(Asset.new(:locale => 'ca'))
    end

    test 'uhook_edit_asset should redirect if not current locale' do
      Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      Ubiquo::AssetsController.any_instance.expects(:ubiquo_assets_path).at_least_once.returns('')
      Ubiquo::AssetsController.any_instance.expects(:redirect_to).at_least_once
      Ubiquo::AssetsController.new.uhook_edit_asset Asset.new(:locale => 'en')
      assert_equal false, Ubiquo::AssetsController.new.uhook_edit_asset(Asset.new(:locale => 'en'))
    end

    test 'uhook_create_asset_should_return_new_asset_with_current_locale' do
      mock_asset_params
      Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      %w{AssetPublic AssetPrivate}.each do |visibility|
        asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
        assert_equal visibility, asset.class.to_s
        assert_equal 'ca', asset.locale
        assert asset.new_record?
      end
    end

    test 'uhook_create_asset with from parameter should reassign resource' do
      from_asset = AssetPublic.create(:resource => 'resource', :name => 'asset')
      mock_asset_params :from => from_asset.id
      Ubiquo::AssetsController.any_instance.expects(:current_locale).at_least_once.returns('ca')
      %w{AssetPublic AssetPrivate}.each do |visibility|
        asset = Ubiquo::AssetsController.new.uhook_create_asset visibility.constantize
        assert_equal from_asset.resource_file_name, asset.resource_file_name
      end
    end

    test 'uhook_destroy_asset_should_destroy_asset' do
      Asset.any_instance.expects(:destroy).returns(:value)
      mock_asset_params :destroy_content => false
      assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
    end

    test 'uhook_destroy_asset_should_destroy_asset_content' do
      Asset.any_instance.expects(:destroy_content).returns(:value)
      mock_asset_params :destroy_content => true
      assert_equal :value, Ubiquo::AssetsController.new.uhook_destroy_asset(Asset.new)
    end

    test 'uhook_asset_filters_should_add_a_locale_filter' do
      filter_set = mock()
      filter_set.expects(:locale).returns(true)

      I18n::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_filters
      end

      assert I18n::UbiquoAssetsController::Helper.uhook_asset_filters(filter_set)
    end

    test 'uhook_edit_asset_sidebar_should_return_show_translations_links' do
      mock_media_helper
      I18n::UbiquoAssetsController::Helper.expects(:show_translations).at_least_once.returns('links')
      I18n::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_edit_asset_sidebar
      end
      assert_equal 'links', I18n::UbiquoAssetsController::Helper.uhook_edit_asset_sidebar(Asset.new)
    end

    test 'uhook_new_asset_sidebar should return show translations links' do
      mock_media_helper
      I18n::UbiquoAssetsController::Helper.expects(:show_translations).at_least_once.returns('links')
      I18n::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_new_asset_sidebar
      end
      assert_equal 'links', I18n::UbiquoAssetsController::Helper.uhook_new_asset_sidebar(Asset.new)
    end

    test 'uhook_asset_index_actions should return translate and remove link if not current locale' do
      mock_media_helper
      asset = Asset.new(:locale => 'ca')
      I18n::UbiquoAssetsController::Helper.expects(:current_locale).returns('en')
      I18n::UbiquoAssetsController::Helper.expects(:ubiquo_asset_path).with(asset, :destroy_content => true)
      I18n::UbiquoAssetsController::Helper.expects(:new_ubiquo_asset_path).with(:from => asset.content_id)
      I18n::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_index_actions
      end
      actions = I18n::UbiquoAssetsController::Helper.uhook_asset_index_actions asset
      assert actions.is_a?(Array)
      assert_equal 2, actions.size
    end

    test 'uhook_asset_index_actions should return removes and edit links if current locale' do
      mock_media_helper
      asset = Asset.new(:locale => 'ca')
      asset.stubs(:is_resizeable?).returns(true)
      I18n::UbiquoAssetsController::Helper.stubs(:current_locale).returns('ca')
      I18n::UbiquoAssetsController::Helper.expects(:ubiquo_asset_path).with(asset, :destroy_content => true)
      I18n::UbiquoAssetsController::Helper.expects(:ubiquo_asset_path).with(asset)
      I18n::UbiquoAssetsController::Helper.expects(:edit_ubiquo_asset_path).with(asset)
      I18n::UbiquoAssetsController::Helper.expects(:advanced_edit_ubiquo_asset_path).with(asset)
      I18n::UbiquoAssetsController::Helper.expects(:advanced_edit_link_attributes).returns({})

      I18n::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_index_actions
      end
      actions = I18n::UbiquoAssetsController::Helper.uhook_asset_index_actions asset
      assert actions.is_a?(Array)
      assert_equal 4, actions.size
    end

    test 'uhook_asset_form should return content_id field' do
      mock_media_helper
      f = stub_everything
      f.expects(:hidden_field).with(:content_id).returns('')
      I18n::UbiquoAssetsController::Helper.expects(:params).returns({:from => 100})
      I18n::UbiquoAssetsController::Helper.expects(:hidden_field_tag).with(:from, 100).returns('')
      I18n::UbiquoAssetsController::Helper.module_eval do
        module_function :uhook_asset_form
      end
      I18n::UbiquoAssetsController::Helper.uhook_asset_form(f)
    end

    test 'uhook_media_attachment should add translation_shared option if set' do
      Asset.class_eval do
        media_attachment :simple
      end
      Asset.uhook_media_attachment :simple, {:translation_shared => true}
      assert Asset.reflections[:simple].options[:translation_shared]
    end

    test 'uhook_media_attachment should not add translation_shared option if not set' do
      Asset.class_eval do
        media_attachment :simple
      end
      Asset.uhook_media_attachment :simple, {:translation_shared => false}
      assert !Asset.reflections[:simple].options[:translation_shared]
    end

    test 'should not share attachments between translations' do
      AssetPublic.class_eval do
        media_attachment :photo
      end

      asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
      translated_asset = asset.translate('en', :copy_all => true)
      translated_asset.save

      AssetRelation.create

      asset.photo << AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')
      assert_equal 0, translated_asset.reload.photo.size
    end

    test 'should share attachments between translations' do
      AssetPublic.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
      translated_asset = asset.translate('en', :copy_all => true)
      translated_asset.save

      asset.photo << AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')
      assert_equal 1, translated_asset.reload.photo.size
      assert_equal 'ca', translated_asset.photo.first.locale
    end

    test 'should share attachments between translations when assignating' do
      AssetPublic.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
      translated_asset = asset.translate('en', :copy_all => true)
      translated_asset.save

      asset.photo = [AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')]
      assert_equal 1, translated_asset.reload.photo.size
      assert_equal 'ca', translated_asset.photo.first.locale
    end

    test 'should only update asset relation name in one translation' do
      AssetPublic.class_eval do
        media_attachment :photo, :translation_shared => true
      end

      Locale.current = 'ca'
      asset = AssetPublic.create :locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'asset'
      translated_asset = asset.translate('en', :copy_all => true)
      translated_asset.save
      asset.photo << original_photo = AssetPublic.create(:locale => 'ca', :resource => Tempfile.new('tmp'), :name => 'photo')

      # save the original name in the translation and then update it
      original_name = AssetRelation.name_for_asset :photo, translated_asset.reload.photo.first, translated_asset

      Locale.current = 'en'
      translated_asset.photo_attributes = [{
        "id" => translated_asset.photo_asset_relations.first.id,
        "asset_id" => original_photo.id,
        "name" => 'newname'
      }]
      translated_asset.save

      # name successfully changed
      assert_equal 'newname', AssetRelation.first(:conditions => {:related_object_id => translated_asset.id}).name
      # translation untouched
      assert_equal original_name, AssetRelation.first(:conditions => {:related_object_id => asset.id}).name
    end

    test "asset_clone does not keep the content_id" do
      a = AssetPublic.create({
        :name => "Created asset",
        :description => "Description",
        :resource => test_file,
      })

      a = a.clone
      assert_nil( a.content_id )
    end

  else
    puts 'ubiquo_i18n not found, omitting UbiquoMedia::Connectors::I18n tests'
  end
end
