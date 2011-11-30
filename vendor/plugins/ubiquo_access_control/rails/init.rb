require 'ubiquo_access_control'

Ubiquo::Plugin.register(:ubiquo_access_control, directory, config) do |config|
  
  config.add :role_access_control, lambda{
    access_control :DEFAULT => "role_management"
  }
  config.add :role_permit, lambda{
    permit?("role_management")
  }
  
  config.add :roles_elements_per_page
  config.add_inheritance :roles_elements_per_page, :elements_per_page
  
  config.add :roles_default_order_field, 'id'
  config.add :roles_default_sort_order, 'desc'
  
end
