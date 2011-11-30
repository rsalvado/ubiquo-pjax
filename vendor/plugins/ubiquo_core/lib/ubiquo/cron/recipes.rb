Capistrano::Configuration.instance.load do

  set :cron_user, user

  before "deploy:update_code",     "ubiquo:cron:update_crontab"
  after  "deploy:finalize_update", "ubiquo:cron:delete_crontab"

  namespace :ubiquo do
    namespace :cron do

      task :update_crontab => :environment, :roles => :cron do
        Ubiquo::Cron::Crontab.install!
      end

      task :delete_crontab, :roles => :cron do
        `crontab -r`
        sleep 30 # Let's give some time for things to finish
      end

    end
  end

end
