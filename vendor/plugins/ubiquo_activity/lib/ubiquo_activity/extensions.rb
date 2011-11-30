module UbiquoActivity
  module Extensions
    autoload :Helper, 'ubiquo_activity/extensions/helper'
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoActivity::Extensions::Helper)
