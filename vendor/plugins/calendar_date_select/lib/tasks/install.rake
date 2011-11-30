namespace :calendardateselect do
  desc "Install static content (Javascript, stylesheets and images) for calendardateselect plugin"
  task :install do

    source_public_directories = [
      'javascripts/calendar_date_select',
      'stylesheets/calendar_date_select',
      'images/calendar_date_select',
      'javascripts/calendar_date_select/locale'
    ]
     
    source_public_directories.each do |source_dir|
      source = File.join(File.dirname(__FILE__), "../public", source_dir)
      dest = File.join(RAILS_ROOT, "public", source_dir)
      FileUtils.mkdir_p(dest)
      FileUtils.cp(Dir.glob(source+'/*.*'), dest)
      puts "** Populating directory: #{dest}"
    end
  end
end
