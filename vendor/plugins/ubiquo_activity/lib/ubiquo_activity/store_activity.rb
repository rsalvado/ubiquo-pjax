module UbiquoActivity
  module StoreActivity
    def self.included klass
      klass.send :include, InstanceMethods
    end
    
    module InstanceMethods
      # Creates a ActivityInfo record with:
      #   - status, info, action, controller, related_object and ubiquo_user
      #
      # Expected params:
      #   - status, object = nil, info = {}
      def store_activity *args
        info = args.extract_options!
        status, object = args
        activity_options = { 
          :status => status.to_s,
          :info => info.to_yaml,
        }
        if object
          activity_options.merge!({
            :related_object_id => object.id,
            :related_object_type => object.class.to_s,
          })
        end
        
        begin
          ActivityInfo.create!(activity_options.merge(request_activity_options))
        rescue ActiveRecord::RecordInvalid => error
          logger.info "[ubiquo_activity] Fail trying register activity info: #{error}"
        end
      end
      
      private
      
      def request_activity_options
        { 
          :controller => params[:controller],
          :action => params[:action],
          :ubiquo_user_id => current_ubiquo_user.id,
        }
      end
    end
  end
end
