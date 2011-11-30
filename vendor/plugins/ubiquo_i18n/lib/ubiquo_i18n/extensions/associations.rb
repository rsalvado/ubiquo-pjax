module UbiquoI18n
  module Extensions
    module Associations

      def self.append_features(base)
        base.send :include, InstanceMethods
        base.alias_method_chain :collection_accessor_methods, :shared_translations
        base.alias_method_chain :association_accessor_methods, :shared_translations
      end

      module InstanceMethods
        def collection_accessor_methods_with_shared_translations(reflection, association_proxy_class, writer = true)
          collection_accessor_methods_without_shared_translations(reflection, association_proxy_class, writer)
          process_translation_shared reflection
        end

        def association_accessor_methods_with_shared_translations(reflection, association_proxy_class)
          association_accessor_methods_without_shared_translations(reflection, association_proxy_class)
          process_translation_shared reflection
        end
      end
    end
  end
end