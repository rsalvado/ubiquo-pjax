module UbiquoCategories
  module Connectors
    autoload :Base, "ubiquo_categories/connectors/base"
    autoload :Standard, "ubiquo_categories/connectors/standard"
    autoload :I18n, "ubiquo_categories/connectors/i18n"
    
    def self.load!
      "UbiquoCategories::Connectors::#{Ubiquo::Config.context(:ubiquo_categories).get(:connector).to_s.camelize}".constantize.load!
    end
  end
end
