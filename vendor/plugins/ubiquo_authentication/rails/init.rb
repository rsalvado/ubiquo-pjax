require 'ubiquo_authentication'

Ubiquo::Plugin.register(:ubiquo_authentication, directory, config) do |config|
  
  #How many time a user must be remembered if checks 'remember me' options when log in.
  config.add :remember_time, 2.weeks
  
  #The permission related with user management
  config.add :user_navigator_permission, lambda{
    permit?("ubiquo_user_management")
  } 
  #The access control line related with user management
  config.add :user_access_control, lambda{
    access_control :DEFAULT => "ubiquo_user_management"
  }
  
  #Default user list size. It's special because it's boxed list.
  #Is setted to 24 because boxes size is static and can show 2, 3 or 4 normally, and 24%2 = 24%3 = 24%4 = 0
  config.add :ubiquo_users_elements_per_page, 24
  
  #Configuration for toggle admin filter in ubiquo users list
  config.add :ubiquo_users_admin_filter_enabled, true
  #Configuration for toggle string filter in ubiquo users list
  config.add :ubiquo_users_string_filter_enabled, true

  #Configuration for modify default order field for ubiquo users list
  config.add :ubiquo_users_default_order_field, 'ubiquo_users.id'
  
  #Configuration for modify sort order for ubiquo users list
  config.add :ubiquo_users_default_sort_order, 'DESC'
end


