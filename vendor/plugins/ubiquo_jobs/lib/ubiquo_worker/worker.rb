module UbiquoWorker

  class Worker
    attr_accessor :name, :sleep_time, :sleep_interval, :pid_file_path, :shutdown

    def initialize(name, options = {})
      raise ArgumentError, "A worker name is required" if name.blank?
      @logger = Rails.logger
      @logger.auto_flushing = 1 # default is 1000 lines
      self.name = name
      self.pid_file_path = options[:pid_file_path] || Rails.root + "tmp/pids/#{name}"
      self.sleep_time = options[:sleep_time]
      self.sleep_interval = options[:sleep_interval] || 1.0
      self.shutdown = false
    end

    # This method will start executing the planified jobs.
    # If no job is available, the worker will sleep for sleep_time sec.
    def run!
      daemon_handle_signals
      with_pid_file do
        while (!shutdown) do
          begin
            job = UbiquoJobs.manager.get(name)
            if job
              log "executing job #{job.id}"
              job.run!
              result_msg = "job #{job.id} finished - "
              if job.state == UbiquoJobs::Jobs::Base::STATES[:finished]
                log "#{result_msg} Ok"
              else
                log "#{result_msg} ERROR", :error
                log "Error log: #{job.error_log}", :error
                if job.state == UbiquoJobs::Jobs::Base::STATES[:error]
                  log "Job #{job.id} will not be retried", :error
                end
              end
            else
              log "no job available"
              wait
            end
          rescue StandardError
            log "Worker got an exception with job #{job.id rescue nil}", :error
            log $!.inspect
            wait
          rescue Exception
            log "Unexpected exception! Worker main loop ended", :error
            log $!.inspect
            raise $!
          end
        end
      end
    end

    private

    def with_pid_file
      pid_directory = File.dirname(pid_file_path)
      Dir.mkdir(pid_directory) unless File.exist?(pid_directory)
      raise ArgumentError unless block_given?
      if File.exists? pid_file_path
        log "Existing pid file: #{pid_file_path}"
        existing_pid = File.read(pid_file_path).to_i
        if existing_pid > 0
          begin
            Process.kill(0, existing_pid)
            log "Process with pid #{existing_pid} already running. Aborting...", :error
            abort
          rescue Errno::ESRCH
            log "Process with pid #{existing_pid} not running. Cleaning pid file and continuing..."
            store_pid
          rescue Errno::EPERM
            log "No permission to query process with id #{existing_pid}. Changed uid, please do investigate. Aborting...", :error
            abort
          end
        else
          log "pid file doesnt contain an integer?", :error
          abort
        end
      else
        store_pid
      end
      yield
      cleanup_pid_file
    end

    def store_pid
      File.open(pid_file_path, 'w') {|f| f.write(Process.pid) }
    end

    def cleanup_pid_file
      File.delete pid_file_path if File.exists? pid_file_path
    end

    def daemon_handle_signals
      Signal.trap("TERM") do
        log "Caught TERM signal, terminating ..."
        self.shutdown = true
      end
    end

    def wait
      time_slept = 0
      while time_slept < self.sleep_time
        break if shutdown
        sleep sleep_interval
        time_slept = time_slept + sleep_interval
      end
    end

    def log(message, severity=:info)
      log_time = Time.now.strftime("%b %d %H:%M:%S")
      log_message = "#{log_time} [UBIQUO WORKER ##{name}] - #{message}"
      if Rails.env == 'development'
        puts log_message
      else
        @logger.send(severity, log_message)
      end
    end

  end
end


