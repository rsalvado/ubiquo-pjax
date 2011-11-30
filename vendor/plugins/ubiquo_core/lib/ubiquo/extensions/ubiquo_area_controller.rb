module Ubiquo
  module Extensions
    # This is a hook module to include anything to UbiquoAreaController
    # DEPRECATED: This module has been subsumed into Loader and will be removed in 0.9
    module UbiquoAreaController
      def self.included(klass)
        if @include_after
          @include_after.each{|k| klass.send(:include, k)}
        end
        if @extend_after
          @extend_after.each{|k| klass.send(:extend, k)}
        end
        if @helper_after
          @helper_after.each{|k| klass.send(:helper, k)}
        end
        # send the stuff in the new module
        klass.send(:include, Ubiquo::Extensions::UbiquoController)
      end
      
      # Includes a klass inside UbiquoAreaController
      # Use this instead of sending direct includes
      def self.append_include(klass)
        ActiveSupport::Deprecation.warn("Ubiquo::Extensions::UbiquoAreaController is deprecated! Use Ubiquo::Extensions::Loader instead.", caller)
        @include_after ||= []
        @include_after << klass
      end

      # Extends UbiquoAreaController with klass
      # Use this instead of sending direct extends
      def self.append_extend(klass)
        ActiveSupport::Deprecation.warn("Ubiquo::Extensions::UbiquoAreaController is deprecated! Use Ubiquo::Extensions::Loader instead.", caller)
        @extend_after ||= []
        @extend_after << klass
      end

      # Adds klass as a helper inside UbiquoAreaController
      # Use this instead of sending direct helper calls
      def self.append_helper(klass)
        ActiveSupport::Deprecation.warn("Ubiquo::Extensions::UbiquoAreaController is deprecated! Use Ubiquo::Extensions::Loader instead.", caller)
        @helper_after ||= []
        @helper_after << klass
      end
    end
  end
end
