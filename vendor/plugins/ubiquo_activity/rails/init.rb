require 'ubiquo_activity'

Ubiquo::Plugin.register(:ubiquo_activity, directory, config) do |config|
  config.add :activities_elements_per_page
  config.add_inheritance :activities_elements_per_page, :elements_per_page
  config.add :activity_info_access_control, lambda { 
    access_control :DEFAULT => 'activity_info_management'
  }
  config.add :activity_info_permit, lambda {
    permit?('actitivy_info_management')
  }
  config.add :activities_date_filter_enabled, true  
  config.add :activities_user_filter_enabled, true
  config.add :activities_controller_filter_enabled, true
  config.add :activities_action_filter_enabled, true
  config.add :activities_status_filter_enabled, true
  config.add :activities_default_order_field, 'activity_infos.created_at'
  config.add :activities_default_sort_order, 'desc'
  # partial name for the activity_info index list
  config.add :info_list_partial, 'standard'
end
