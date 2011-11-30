module UbiquoCategories
  module Connectors
    class Base < Ubiquo::Connectors::Base

      # Load all the modules required for an UbiquoCategories connector
      def self.load!
        ::Category.reset_column_information
        if current = UbiquoCategories::Connectors::Base.current_connector
          current.unload!
        end
        return if validate_requirements == false
        prepare_mocks if Rails.env.test?
        ::ActiveRecord::Base.send(:include, self::ActiveRecord::Base)
        ::Category.send(:include, self::Category)
        ::CategorySet.send(:include, self::CategorySet)
        ::Ubiquo::Extensions::Loader.append_helper(:UbiquoController, self::UbiquoHelpers::Helper)
        ::Ubiquo::CategoriesController.send(:include, self::UbiquoCategoriesController)
        ::ActiveRecord::Migration.send(:include, self::Migration)
        UbiquoCategories::Connectors::Base.set_current_connector self
      end

    end
  end
end
