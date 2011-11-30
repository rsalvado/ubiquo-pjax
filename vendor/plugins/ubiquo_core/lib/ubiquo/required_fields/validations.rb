module Ubiquo
  module RequiredFields
    module Validations      
      
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :alias_method_chain, :validates_presence_of, :required_fields
      end
      
      module InstanceMethods
        #
        # Adds field names to required fields.
        #
        def validates_presence_of_with_required_fields(*attr_names)
          validates_presence_of_without_required_fields(*attr_names)
          attr_names.extract_options!
          required_fields(*attr_names)
        end
      end
    end
  end
end

