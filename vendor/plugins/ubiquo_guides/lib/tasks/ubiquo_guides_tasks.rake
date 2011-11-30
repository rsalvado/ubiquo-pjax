namespace :ubiquo do
  UBIQUO_GUIDES_ROOT = File.join(File.dirname(__FILE__), '..', '..')

  desc 'Generate guides (for authors), use ONLY=foo to process just "foo.textile"'
  task :guides do
    ENV["WARN_BROKEN_LINKS"] = "1" # authors can't disable this
    ruby File.join(UBIQUO_GUIDES_ROOT, "guides/rails_guides.rb")
  end

  namespace :guides do

    def upload_guide(dst_path)
      src_path = File.join(UBIQUO_GUIDES_ROOT, "guides/output")
      dst_path ||= "~/guides/edge"
      system("scp -r #{src_path}/* ubiquo@guides.ubiquo.me:#{dst_path}")
    end

    desc 'Uploads edge guides to the ubiquo guide server'
    task :publish_edge do
      system("cd #{UBIQUO_GUIDES_ROOT} && git checkout master && cd -")
      Rake::Task['ubiquo:guides'].invoke
      upload_guide("~/guides/edge")
    end
    desc 'Uploads 0.7-stable to the ubiquo  guide server'
    task :publish_07stable do
      system("cd #{UBIQUO_GUIDES_ROOT} && git checkout 0.7-stable && cd -")
      Rake::Task['ubiquo:guides'].invoke
      upload_guide("~/guides/0.7-stable")
    end
  end

end
