module Ubiquo
  module NavigationLinks
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, Ubiquo::NavigationLinks::Helpers)
