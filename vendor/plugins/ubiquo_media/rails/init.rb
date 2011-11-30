require 'ubiquo_media'

config.after_initialize do
  UbiquoMedia::Connectors.load!
  Ubiquo::Helpers::UbiquoFormBuilder.initialize_method("media_selector",
  Ubiquo::Config.context(:ubiquo_media).get(:ubiquo_form_builder_media_selector_tag_options).dup)
end

Ubiquo::Plugin.register(:ubiquo_media, directory, config) do |config|
  config.add :assets_elements_per_page
  config.add_inheritance :assets_elements_per_page, :elements_per_page
  config.add :media_selector_list_size, 6
  config.add :assets_access_control, lambda{
    access_control :DEFAULT => 'media_management'
  }
  config.add :assets_permit, lambda{
    permit?('media_management')
  }
  config.add :assets_string_filter_enabled, true
  config.add :assets_tags_filter_enabled, true
  config.add :assets_asset_types_filter_enabled, true
  config.add :assets_asset_visibility_filter_enabled, true
  config.add :assets_date_filter_enabled, true
  config.add :assets_default_order_field, 'assets.id'
  config.add :assets_default_sort_order, 'asc'
  config.add :mime_types, { :image => ["image"],
                            :video => ["video"],
                            :doc => ["text", "pdf", "msword"],
                            :audio => ["audio"],
                            :flash => ["swf", "x-shockwave-flash"] }
  config.add :media_styles_list, { :thumb => "100x100>", :base_to_crop => "590x442>" }
  # a hash or a proc (receives the style name and value) containing options that apply to all styles
  config.add :media_styles_options, {}
  config.add :media_processors_list, [:resize_and_crop]
  #The styles that belong to ubiquo and are part of the core
  config.add :media_core_styles, [:thumb, :base_to_crop]
  # Advanced edit options (aka Crop&resize)
  config.add :assets_default_keep_backup, true
  # Warn the user when updating an asset that is related to an instance
  config.add :advanced_edit_warn_user_when_changing_asset_in_use, false
  # When editing advanced from a media selector, allow to restore to uploaded asset.
  config.add :advanced_edit_allow_restore_from_media_selector, true
  # When false, we'll show "save as" option only on the crop tab and not on the formats.
  config.add :advanced_edit_allow_save_as_for_all_styles, false


  config.add :force_visibility, "public" # set to public or protected to force it to the entire application

  # Connectors available in the application.
  # These connectors will be tested against the Base uhooks api
  config.add :available_connectors, [:standard]

  # Currently enabled connector
  config.add :connector, :standard
  config.add :media_storage, :filesystem
  config.add :progress_bar, false

  config.add(:ubiquo_form_builder_media_selector_tag_options,
    { :group => {:type => :fieldset, :class => "group-related-assets"},
      :label_as_legend => true
    })
end

