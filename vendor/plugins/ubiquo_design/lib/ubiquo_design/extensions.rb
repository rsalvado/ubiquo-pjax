module UbiquoDesign
  module Extensions
    autoload :Helper, "ubiquo_design/extensions/helper"
    autoload :TestHelper, "ubiquo_design/extensions/test_helper"

    module RailsGenerator
      [:Create, :Destroy].each { |m| autoload m, 'ubiquo_design/extensions/rails_generator' }
    end
  end
end

ActionController::Base.helper(UbiquoDesign::Extensions::Helper)
ActionView::Base.send(:include, UbiquoDesign::Extensions::Helper)

if Rails.env.test?
  ActiveSupport::TestCase.send(:include, UbiquoDesign::Extensions::TestHelper)
end

Rails::Generator::Commands::Create.send(:include, UbiquoDesign::Extensions::RailsGenerator::Create)
Rails::Generator::Commands::Destroy.send(:include, UbiquoDesign::Extensions::RailsGenerator::Destroy)
