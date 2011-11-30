require 'ubiquo_jobs'

Ubiquo::Plugin.register(:ubiquo_jobs, directory, config) do |config|
  config.add :job_manager_class, UbiquoJobs::Managers::ActiveManager
  config.add :job_notifier_class, UbiquoJobs::Helpers::Notifier
end
