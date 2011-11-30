class UbiquoPluginGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    super
  end

  def manifest
    record do |m|
      custom_plugin = File.join('vendor/plugins', @name)
      m.directory(File.join(custom_plugin, 'app/views'))
      m.directory(File.join(custom_plugin, 'app/controllers'))
      m.directory(File.join(custom_plugin, 'app/models'))
      m.directory(File.join(custom_plugin, 'app/helpers'))
      m.directory(File.join(custom_plugin, 'config/locales'))
      m.directory(File.join(custom_plugin, 'install'))
      m.directory(File.join(custom_plugin, 'lib'))
      m.directory(File.join(custom_plugin, 'rails'))
      m.directory(File.join(custom_plugin, 'test/fixtures'))
      m.directory(File.join(custom_plugin, 'test/functional'))
      m.directory(File.join(custom_plugin, 'test/unit'))

      m.template("init.rb", File.join(custom_plugin, 'rails', 'init.rb'))

    end
  end

  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} ubiquo_plugin plugin_name"
    end

    def add_options!(opt)

    end

end
