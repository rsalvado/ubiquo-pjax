module Ubiquo
  module Extensions
    # This is a hook module to include anything to any installed class
    # Allows to circumvent the cache_classes problem for classes not in plugins
    module Loader
      mattr_accessor :extensions, :methods

      self.extensions ||= {}
      self.methods = %w{include extend helper}

      # Returns true if the that symbol has scheduled extensions to be included
      def self.has_extensions?(sym)
        extensions[sym.to_s]
      end

      # Returns a Module that, when included, will provide all the scheduled funcionality for +sym+
      def self.extensions_for(sym)
        Module.new{
          block = Proc.new{|recipient|
            Loader.methods.each do |method|
              Array(Loader.extensions[sym.to_s][method]).each do |k|
                recipient.send(method, k)
              end
            end
          }
          define_method :included, block
          module_function :included
        }
      end

      methods.each do |method|

        self.class_eval <<-EOS
          # Schedules the inclusion of +klass+ inside +recipient+
          # Use this instead of sending direct includes, extends or helpers
          def self.append_#{method}(recipient, klass)            # def self.append_include('UbiquoController', MyModule)
            extensions[recipient.to_s] ||= {}                    #   extensions['UbiquoController'.to_s] ||= {}
            extensions[recipient.to_s]["#{method}"] ||= []       #   extensions['UbiquoController'.to_s]["include"] ||= []
            extensions[recipient.to_s]["#{method}"] << klass     #   extensions['UbiquoController'.to_s]["include"] << klass
            # use class_eval to avoid evaluation of recipient    #   # use class_eval to avoid evaluation of UbiquoController
            class_eval <<-EOCONSTANTIZE                          #   class_eval <<-EOCONSTANTIZE
              if defined?(\#{recipient})                         #     if defined?(UbiquoController)
               \#{recipient}.send("#{method}", klass)            #       UbiquoController.send("include", MyModule)
              end                                                #     end
            EOCONSTANTIZE
          end                                                    # end
        EOS
      end

    end

    # This module acts as a hook to enable Loader in the class that includes it
    module LoaderHook

      # This is the main Loader hook, that is fired in the usual class creation
      # class MyClass (< MyParent); end
      module InheritedHook
        def inherited_with_ubiquo_extensions(subclass)
          inherited_without_ubiquo_extensions(subclass)
          Ubiquo::Extensions.load_extensions_for subclass rescue nil
        end

        def self.included klass
          klass.send :alias_method_chain, :inherited, :ubiquo_extensions
        end
      end

      # This module allows to also fire Loader when defining new classes using
      # the Module#const_set method
      module ConstSetHook
        def const_set_with_ubiquo_extensions(name, klass)
          set_object = const_set_without_ubiquo_extensions(name, klass)
          if set_object.is_a? Class
            Ubiquo::Extensions.load_extensions_for set_object rescue nil
          end
          set_object
        end

        def self.included klass
          klass.send :alias_method_chain, :const_set, :ubiquo_extensions
        end
      end

      def self.included(klass)
        if klass === Module
          # Modules do not have Class#inherited since it is only defined for classes
          Class.instance_eval  { include InheritedHook }
          Module.instance_eval { include ConstSetHook  }
        else
          klass.singleton_class.instance_eval { include InheritedHook, ConstSetHook }
        end
      end
    end

    # Enable the Loader feature broadly
    Module.class_eval { include LoaderHook }

    # Rails is loaded at this point and ActionController::Base will not be aware
    # of the above line since it already has its own aliases, so we need to include
    # it explicitly to have this feature available also on controllers
    ActionController::Base.class_eval { include LoaderHook }
  end
end
