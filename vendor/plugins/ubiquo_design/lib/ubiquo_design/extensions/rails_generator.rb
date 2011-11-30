module UbiquoDesign
  module Extensions
    module RailsGenerator
      module Create
        # Modify design_structure.rb and include the new widget
        def ubiquo_widget(name)
          logger.widget "#{name}"
          unless options[:pretend]
            gsub_file 'config/initializers/design_structure.rb', /(^end$)/ do |match|
              "  widget :#{name}\n#{match}"
            end
          end
        end
      end
      module Destroy
        # Modify design_structure.rb deleting the widget
        def ubiquo_widget(name)
          logger.widget "#{name}"
          gsub_file 'config/initializers/design_structure.rb', /(\s+widget\s+:#{name})/, ''
        end
      end
    end
  end
end
