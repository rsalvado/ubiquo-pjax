require 'ubiquo_activity/extensions'
require 'ubiquo_activity/version.rb'

module UbiquoActivity
  autoload :StoreActivity, 'ubiquo_activity/store_activity'
  autoload :RegisterActivity, 'ubiquo_activity/register_activity'  
end
Ubiquo::Extensions::Loader.append_include(:UbiquoController, UbiquoActivity::StoreActivity)
Ubiquo::Extensions::Loader.append_include(:UbiquoController, UbiquoActivity::RegisterActivity)
