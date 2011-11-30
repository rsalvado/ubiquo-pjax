module Ubiquo
  module RequiredFields
    module FormTagHelper
      
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :alias_method_chain, :label_tag, :asterisk
      end
      
      module InstanceMethods
        
        # appends an asterisk to the text if needed
        def label_tag_with_asterisk(name, text = nil, options = {})
          if !text.nil? && options["append_asterisk"] == true
            span_class = Ubiquo::Config.get(:required_field_class)
            text += "<span class= #{span_class} > * </span>"
          end
          options.delete("append_asterisk")
          label_tag_without_asterisk(name, text, options)
        end
      end
    end
  end
end
