module UbiquoDesign
  module Connectors
    class Base < Ubiquo::Connectors::Base

      # loads this connector. It's called if that connector is used
      def self.load!
        [::Widget].each(&:reset_column_information)
        if current = UbiquoDesign::Connectors::Base.current_connector
          current.unload!
        end
        validate_requirements
        ::Page.send(:include, self::Page)
        ::PagesController.send(:include, self::PagesController)
        ::Ubiquo::DesignsController.send(:include, self::UbiquoDesignsHelper)
        ::Ubiquo::WidgetsController.send(:include, self::UbiquoDesignsHelper)
        ::Ubiquo::BlocksController.send(:include, self::UbiquoDesignsHelper)
        ::Ubiquo::WidgetsController.send(:include, self::UbiquoWidgetsController)
        ::Ubiquo::StaticPagesController.send(:include, self::UbiquoStaticPagesController)
        ::Ubiquo::PagesController.send(:include, self::UbiquoPagesController)
        ::ActiveRecord::Migration.send(:include, self::Migration)
        ::UbiquoDesign::RenderPage.send(:include, self::RenderPage)
        UbiquoDesign::Connectors::Base.set_current_connector self
      end

    end
  end
end
