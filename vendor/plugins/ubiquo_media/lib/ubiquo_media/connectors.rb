module UbiquoMedia
  module Connectors
    autoload :Base, "ubiquo_media/connectors/base"
    autoload :Standard, "ubiquo_media/connectors/standard"
    
    def self.load!
      "UbiquoMedia::Connectors::#{Ubiquo::Config.context(:ubiquo_media).get(:connector).to_s.camelize}".constantize.load!
    end
  end
end
