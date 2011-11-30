module UbiquoWorker
  
  autoload :Worker, 'ubiquo_worker/worker'

  # initializes a worker identified by +name+
  # possible options are:
  #   :sleep_time => interval time to look for new jobs (float, default 5.0)
  def self.init(name, options = {})
    default_options = {
      :sleep_time => 5.0
    }
    worker = Worker.new(name, default_options.merge(options))
    worker.run!
  end
end
