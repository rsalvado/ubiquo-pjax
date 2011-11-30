module Ubiquo
  module RequiredFields
    module FormHelper
      
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :alias_method_chain, :label, :asterisk
      end
      
      module InstanceMethods
        # Adds "append_asterisk" option to 'options' parameter if the field is maked as required.
        def label_with_asterisk(object_name, method, text = nil, options = {})
          begin
            object_class = options[:object] ? options[:object].class : object_name.to_s.classify.constantize
            if object_class && 
                object_class.respond_to?(:required_fields) && 
                object_class.required_fields.include?(method)
              options.reverse_merge!("append_asterisk" => true) 
            end
          rescue NameError => e
          end
          label_without_asterisk(object_name, method, text, options)
        end
      end
    end
  end
end
