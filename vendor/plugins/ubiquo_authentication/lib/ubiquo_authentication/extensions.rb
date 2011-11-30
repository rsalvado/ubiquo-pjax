module UbiquoAuthentication
  module Extensions
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoAuthentication::Extensions::Helper)
Ubiquo::Extensions::Loader.append_include(:UbiquoController, UbiquoAuthentication::Extensions::Controller)

if Rails.env.test?
  ActionController::TestCase.send(:include, UbiquoAuthentication::Extensions::TestCase)
  ActionController::TestCase.setup(:login_as)
end
