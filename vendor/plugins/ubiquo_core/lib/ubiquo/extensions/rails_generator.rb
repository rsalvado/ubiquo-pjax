module Ubiquo

  def self.tab_template(name)
    "end
    navigator.add_tab do |tab|
      tab.text = t('ubiquo.#{name.singularize}.title')
      tab.title = t('application.goto', :place => '#{name}')
      tab.link = ubiquo_#{name}_path
      tab.highlights_on({:controller => 'ubiquo/#{name}'})
      tab.highlighted_class = 'active'
    end # Last tab"
  end

  # Adds required rake dependencies to be able to call rake tasks from ubiquo_scaffold
  def self.require_rake
    libs = %w[ rake rake/testtask rake/rdoctask tasks/rails ]
    libs.each { |lib| require lib}
  end

  module Extensions
    module RailsGenerator
      module Create
        # Modify routes.rb and include the namespaced resources
        def namespaced_route_resources(namespace, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
          sentinel = "map.namespace :#{namespace} do |#{namespace}|"

          logger.route "#{namespace}.resources #{resource_list}"
          unless options[:pretend]
            gsub_file(
              'config/routes.rb',
              /([\t| ]*)(#{Regexp.escape(sentinel)})/mi,
              "\\1\\2\n\\1  #{namespace}.resources #{resource_list}\n"
              )
          end
        end

        def nested_route_resources(parent, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')

          unless options[:pretend]
            gsub_file(
              'config/routes.rb',
              /^([\ |\t]*)(\w+\.)(resource[s]?\s[\:|\"]#{parent}\"?)(\sdo\s\|#{parent}\|)$/mi,
              "\\1\\2\\3\\4\n\\1  #{parent}.resources #{resource_list}"
              )
            gsub_file(
              'config/routes.rb',
              /^([\ |\t]*)(\w+\.)(resource[s]?\s[\:|\"]#{parent}\"?)$/mi,
              "\\1\\2\\3 do |#{parent}|\n\\1  #{parent}.resources #{resource_list}\n\\1end"
              )
          end
        end

        # Add ubiquo tab
        def ubiquo_tab(name)
          sentinel = 'end # Last tab'
          unless options[:pretend]
            gsub_file 'app/views/navigators/_main_navtabs.html.erb', /(#{Regexp.escape(sentinel)})/mi do
              Ubiquo::tab_template(name)
            end
          end
        end

        def ubiquo_migration
          Ubiquo::require_rake
          Rake::Task['db:migrate'].execute(nil)
        end
      end
      module Destroy
        # Modify routes.rb deleting the namespaced resources
        def namespaced_route_resources(namespace, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
          look_for = "#{namespace}.resources #{resource_list}\n"
          logger.route "#{namespace}.resources #{resource_list}"
          gsub_file 'config/routes.rb', /(\n\s*#{look_for})/mi, "\n"
        end
        # Remove ubiquo tab only if unmodified
        def ubiquo_tab(name)
          look_for = Ubiquo::tab_template(name)
          gsub_file 'app/views/navigators/_main_navtabs.html.erb', /#{Regexp.escape(look_for)}/mi, 'end # Last tab'
        end

        def nested_route_resources(parent, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')

          unless options[:pretend]
            gsub_file(
              'config/routes.rb',
              /^[^\n]*#{parent}.resources?\s#{resource_list}\n/mi,
              "")
          end
        end

        def ubiquo_migration
          Ubiquo::require_rake
          Rake::Task['db:rollback'].execute(nil)
        end
      end
      module List
        def namespaced_route_resources(namespace, *resources)
          resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
          logger.route "#{namespace}.resources #{resource_list}"
        end
      end
    end
  end
end
