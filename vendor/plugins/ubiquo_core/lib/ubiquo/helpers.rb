module Ubiquo
  module Helpers
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, Ubiquo::Helpers::CoreUbiquoHelpers)
Ubiquo::Extensions::Loader.append_helper(:UbiquoController, Ubiquo::Helpers::ShowHelpers)
ActionController::Base.helper(Ubiquo::Helpers::CorePublicHelpers)
