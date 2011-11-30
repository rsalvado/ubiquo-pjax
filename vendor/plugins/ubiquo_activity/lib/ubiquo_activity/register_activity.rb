module UbiquoActivity
  module RegisterActivity
    def self.included klass
      klass.extend ClassMethods
    end
    
    module ClassMethods
      # After filter that calls store_activity method for each action 
      # specified in params
      def register_activity *actions
        after_filter do |c|
          if actions.include?(c.request[:action].to_sym)
            object_name = c.request[:controller].gsub("ubiquo/", "").singularize
            object = c.instance_variable_get("@" + object_name)
            status = object.errors.blank? ? :successful : :error
            c.store_activity status, object
          end
        end
      end
    end
  end
end
