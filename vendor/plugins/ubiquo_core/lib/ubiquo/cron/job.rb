module Ubiquo
  module Cron

    # Define and run rake tasks or ruby code in the context of an
    # ubiquo application.
    # Used to run cron jobs deals with logging, error alerts and job
    # concurrency.
    class Job

      # Creates a new Job. You can pass some optional values for
      # configuration (options hash).
      #
      # ==== Options
      #
      # * +:logger+ - Will you this logger instance to log messages.
      # * +:debug+ - Boolean, when enabled will log stderr and stout.
      # * +:recipients+ - If present will email errors.
      # * +:lockdir+ - Directory to store lockfiles.
      #
      # ==== Examples
      #
      #  logger = Logger.new(logfile, Logger::DEBUG)
      #  job = Ubiquo::Cron::Job.new(:logger => logger, recipients => 'errors@fail.com')
      def initialize(options = {})
        @logger     = options[:logger]
        @debug      = options[:debug] || false
        @recipients = options[:recipients]
        @lockdir    = options[:lockdir] || File.join(Rails.root, "tmp")
      end

      # Runs the job taking care of logging, error alerts and
      # concurrency.
      #
      # ==== Attributes
      #
      # * +task+ - String which can be either a rake task (with
      # parameters) or ruby code to be executed.
      # * +type+ - Defaults to rake (tries to run the task as a rake
      # task), any other value will try to run it as a script.
      #
      # ==== Examples
      #
      #  # Runs the 'update:statistics' rake task with full param.
      #  job.run 'update:statistics full=true'
      #  # Runs the 'notify_all' User's class method.
      #  job.run 'User.notify_all', :script
      def run(task, type = :rake)
        start = Time.now
        run_msg = build_run_msg task
        @stderr, @stdout = capture_stds do
          lockfile = File.join @lockdir, "cron-" + Digest::MD5.hexdigest(task)
          Lockfile(lockfile, :retries => 0) do
            type == :rake ? Rake::Task[task].invoke : eval(task)
          end
        end
        true
      rescue Lockfile::MaxTriesLockError => e
        error_msg = build_error_msg(e)
        false
      rescue Exception => e
        error_msg = build_error_msg(e)
        if @recipients
          JobMailer.deliver_error(@recipients, task, run_msg, error_msg)
        end
        false
      ensure
        run_msg << " (#{Time.now - start} seconds elapsed)"
        log_task_run(run_msg, error_msg) if @logger
      end

      private

      # Returns a formatted string with error information.
      def build_error_msg(e)
        message = []
        message << tabify("Exception message: #{e.message}") if e.message
        message << build_debug_msg
        message << tabify(e.backtrace) unless e.backtrace.blank?
        message.join("\n")
      end

      # Returns a formatted string with the output from stderr and
      # stdout.
      def build_debug_msg
        message = []
        stds = { @stdout => "Standard output: ", @stderr => "Standard error: " }
        stds.each do |std, name|
          message << tabify(name) << tabify(std) unless std.blank?
        end
        message.join("\n")
        # Return nil if empty
      end

      # Returns a formatted string with execution information.
      def build_run_msg(task)
        date     = Time.now.strftime("%b %d %H:%M:%S")
        hostname = Socket.gethostname
        username = Etc.getpwuid(Process.uid).name
        "#{date} #{hostname} #{$$} (#{username}) JOB (#{task})"
      end

      # Logs job result with just one logger add call.
      def log_task_run(run_msg, error_msg)
        if error_msg
          @logger.add(Logger::ERROR, run_msg + "\n" + error_msg)
        elsif @debug
          @logger.add(Logger::DEBUG, run_msg + "\n" + build_debug_msg)
        else
          @logger.add(Logger::INFO, run_msg)
        end
      end

      # Captures and returns the stderr and the stdout of the passed
      # block.
      def capture_stds(&block)
        real_stderr, $stderr = $stderr, StringIO.new
        real_stdout, $stdout = $stdout, StringIO.new
        yield
        [ $stderr.string, $stdout.string ]
      ensure
        $stdout, $stderr = real_stdout, real_stderr
      end

      # Adds tabs at the start of an string or Array of strings.
      def tabify(item)
        item = item.split("\n") if item.kind_of? String
        item.map { |i| "    " + i }.join("\n")
      end

    end
  end
end
