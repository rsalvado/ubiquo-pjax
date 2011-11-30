namespace :ubiquo do

  plugins = FileList['vendor/plugins/ubiquo_*'].collect { |plugin| File.basename(plugin) }

  desc 'Generates rdoc documentation for all ubiquo plugins'
  task :rdocs => :environment do
    plugins.each { |plugin| Rake::Task["ubiquo:rdocs:#{plugin}"].invoke }
  end

  namespace :rdocs do

    def upload_rdocs(dst_path)
      # TODO: Update rdocs path
      src_path = File.join(Rails.root, "doc/plugins/ubiquo_*")
      dst_path ||= "~/rdocs/edge"
      system("scp -r #{src_path} ubiquo@guides.ubiquo.me:#{dst_path}")
    end

    desc 'Uploads edge rdocs to the ubiquo guide server'
    task :publish_edge => :environment do
      upload_rdocs("~/rdocs/edge")
    end
    desc 'Uploads 0.7-stable rdocs to the ubiquo  guide server'
    task :publish_07stable => :environment do
      upload_rdocs("~/rdocs/0.7-stable")
    end

    # Define doc tasks for each plugin
    plugins.each do |plugin|
      desc "Generate ubiquo documentation for the #{plugin} plugin"
      task(plugin => :environment) do
        plugin_base   = "vendor/plugins/#{plugin}"
        options       = []
        files         = Rake::FileList.new
        options << "-o doc/plugins/#{plugin}"
        options << "--title '#{plugin.titlecase} Plugin Documentation'"
        options << '--line-numbers' << '--inline-source'
        options << '--charset' << 'utf-8'
        options << '-T hanna'

        files.include("#{plugin_base}/lib/**/*.rb")
        if File.exist?("#{plugin_base}/README")
          files.include("#{plugin_base}/README")
          options << "--main '#{plugin_base}/README'"
        end
        files.include("#{plugin_base}/CHANGELOG") if File.exist?("#{plugin_base}/CHANGELOG")

        options << files.to_s

        sh %(rdoc #{options * ' '})
      end
    end

  end

end
