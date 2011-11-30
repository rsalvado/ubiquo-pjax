module UbiquoAccessControl
  module Extensions
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoAccessControl::Extensions::Helper)
if Rails.env.test?
  ActionController::TestCase.send(:include, UbiquoAccessControl::Extensions::TestCase)
end
