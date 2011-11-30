require 'ubiquo_access_control/extensions.rb'

Ubiquo::Extensions::Loader.append_include(:UbiquoController, UbiquoAccessControl::AccessControl)
