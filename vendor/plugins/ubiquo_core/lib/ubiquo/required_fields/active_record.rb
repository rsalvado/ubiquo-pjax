module Ubiquo
  module RequiredFields
    module ActiveRecord
      
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.send :extend, ClassMethods
      end
      
      module InstanceMethods
        #return the required_fields of the class. See Ubiquo::RequiredFields::ActiveRecord::ClassMethods
        def required_fields
          self.class.required_fields
        end
      end
      
      module ClassMethods
        #adds all the arguments to required fields for the class. Initially is empty or inherited from superclass.
        #It returns the arguments, so that can be used as getter too.
        #
        #Example:
        # class YourModel < ActiveRecord::Base
        #   required_fields :name
        # end
        # YourModel.required_fields # [:name]
        def required_fields(*fields)
           @required_fields ||= if self.superclass.respond_to?(:required_fields)
            self.superclass.required_fields
          else
            []
          end
          @required_fields += fields
          @required_fields
        end
      end
      
    end
  end
end
