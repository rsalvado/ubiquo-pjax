module Ubiquo
  module NavigationTabs
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, Ubiquo::NavigationTabs::Helpers)
