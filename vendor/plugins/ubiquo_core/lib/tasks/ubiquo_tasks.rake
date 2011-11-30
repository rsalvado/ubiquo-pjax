require File.dirname(__FILE__) + "/../ubiquo/tasks/files"

namespace :ubiquo do
  namespace :test do
    desc "Preparation for ubiquo testing"
    task :prepare => "db:test:prepare" do
      include Ubiquo::Tasks::Files
      install_ubiquo_fixtures
    end
  end

  Rake::TestTask.new(:test => "ubiquo:test:prepare") do |t|
    t.libs << "test"
    target_plugin = ENV.delete("PLUGIN") || "ubiquo**"
    t.pattern = File.join('vendor', 'plugins', target_plugin, 'test', '**', '*_test.rb')
    t.verbose = false
  end

  Rake::Task['ubiquo:test'].comment = "Run all ubiquo plugins tests"

  desc "Install ubiquo migrations and fixtures to respective folders in the app"
  task :install do
    include Ubiquo::Tasks::Files
    overwrite = ENV.delete("OVERWRITE")
    overwrite = overwrite == 'true' || overwrite == 'yes'  ? true : false
    copy_dir(Dir.glob(Rails.root.join('vendor', 'plugins', 'ubiquo**', 'install')), "/", :force => overwrite)
  end

  desc "Run given command inside each plugin directory."
  task :foreach, [ :command ] do |t, args|
    ubiquo_dependencies = %w[ calendar_date_select exception_notification paperclip responds_to_parent tiny_mce ]
    plugin_directory = Rails.root.join('vendor', 'plugins')
    ubiquo_plugins = Dir.glob(File.join(plugin_directory,"ubiquo_*")).map { |file| file.split("/").last }
    plugins = ubiquo_dependencies + ubiquo_plugins
    args.with_defaults(:command => 'git pull')
    plugins.each do |plugin|
      plugin_path = File.join(plugin_directory, plugin)
      command = "cd #{plugin_path} && #{args.command}"
      $stdout.puts "\nRunning #{command}"
      system(command)
      exit 1 if $? != 0
    end
  end

end
