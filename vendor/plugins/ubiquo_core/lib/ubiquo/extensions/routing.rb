module Ubiquo
  module Extensions
    module Routing
      # Loads the set of routes from within a plugin and evaluates them at this
      # point within an application's main <tt>routes.rb</tt> file.
      #
      # Plugin routes are loaded from <tt><plugin_root>/routes.rb</tt>.
      def from_plugin(name, options = {})
        # At the point in which routing is loaded, we cannot guarantee that all
        # plugins are in Rails.plugins, so instead we need to use find_plugin_path
        self.with_options(options) do |map|
          routes_path = Rails.root.join('vendor', 'plugins', name.to_s, 'config', 'plugin_routes.rb')
          # logger.debug "loading routes from #{routes_path}"
          eval(IO.read(routes_path), binding, routes_path) if File.file?(routes_path)
        end
      end
    end
  end
end
