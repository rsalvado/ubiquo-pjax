module UbiquoDesign
  module Connectors
    autoload :Base, "ubiquo_design/connectors/base"
    autoload :Standard, "ubiquo_design/connectors/standard"
    autoload :WidgetTranslation, "ubiquo_design/connectors/widget_translation"
    
    def self.load!
      "UbiquoDesign::Connectors::#{Ubiquo::Config.context(:ubiquo_design).get(:connector).to_s.camelize}".constantize.load!
    end
  end
end
