module UbiquoMedia
  module Connectors
    class Base < Ubiquo::Connectors::Base

      # Load all the modules required for an UbiquoMedia connector
      def self.load!
        [::Asset, ::AssetPublic, ::AssetPrivate, ::AssetRelation].each(&:reset_column_information)
        if current = UbiquoMedia::Connectors::Base.current_connector
          current.unload!
        end

        validate_requirements
        prepare_mocks if Rails.env.test?

        ::ActiveRecord::Base.send(:include, self::ActiveRecord::Base)
        ::Asset.send(:include, self::Asset)
        ::AssetRelation.send(:include, self::AssetRelation)
        ::Ubiquo::AssetsController.send(:include, self::UbiquoAssetsController)
        ::ActiveRecord::Migration.send(:include, self::Migration)
        UbiquoMedia::Connectors::Base.set_current_connector self
      end

    end
  end
end
