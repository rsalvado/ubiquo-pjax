module UbiquoI18n
  module Extensions
    module NamedScope
   
      def self.included(klass)
        klass.alias_method_chain :method_missing, :locale_scope
      end
      
      # This method is executed when a named scope is being resolved. It will
      # check if this scope is the locale() scope, and if so, will set all
      # the necessary for the actual locale filter be applied
      def method_missing_with_locale_scope(method, *args, &block)
        if proxy_options[:locale_scoped] && proxy_options[:locale_list]
          # this is a locale() call
          # find the model we are acting on
          klass = proxy_scope
          while !(Class === klass)
            if klass.respond_to?(:proxy_scope)
              klass = klass.proxy_scope
            elsif klass.is_a?(Array)
              klass = klass.first.class
            end
          end
          # tell the (adequate) model that we are heading there
          if klass.respond_to?(:really_translatable_class)
            klass = klass.really_translatable_class
            unless klass.instance_variable_get(:@setting_locale_list)
              klass.instance_variable_set(:@locale_scoped, true)
              current_locale_list = klass.instance_variable_get(:@current_locale_list)
              (current_locale_list ||= []) << proxy_options[:locale_list]
              klass.instance_variable_set(:@current_locale_list, current_locale_list)
            end
            begin
              # avoid coming here a second time to reset the current_locale_list
              klass.instance_variable_set(:@setting_locale_list, true)
              return method_missing_without_locale_scope(method, *args, &block)
            ensure
              klass.instance_variable_set(:@setting_locale_list, false)
            end
          end
        end
        method_missing_without_locale_scope(method, *args, &block)
      end      
    end
  end
end
