require 'ubiquo_jobs/extensions.rb'
require 'ubiquo_jobs/version.rb'

module UbiquoJobs

  # Return the manager class to use. You can override the default by setting
  # the :job_manager_class in ubiquo config:
  #   Ubiquo::Config.context(:ubiquo_jobs).set(
  #     :job_manager_class, 
  #     UbiquoJobs::Managers::ActiveManager
  #   )
  def self.manager
    Ubiquo::Config.context(:ubiquo_jobs).get(:job_manager_class)
  end
  
  # Return the notifier class to use. You can override the default by using
  # the :job_notifier_class in ubiquo config:
  #   Ubiquo::Config.context(:ubiquo_jobs).set(
  #     :job_notifier_class, 
  #     UbiquoJobs::Helpers::Notifier
  #   )
  def self.notifier
    Ubiquo::Config.context(:ubiquo_jobs).get(:job_notifier_class)
  end
end
