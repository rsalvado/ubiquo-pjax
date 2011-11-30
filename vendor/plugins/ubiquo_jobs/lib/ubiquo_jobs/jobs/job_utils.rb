module UbiquoJobs
  module Jobs
    module JobUtils

      def self.included(job_class)
        # add methods in JobClassMethods into the job class
        job_class.extend(JobClassMethods)
      end

      # List of states a Job can be
      STATES = {:waiting => 0, :instantiated => 1, :started => 2, :finished => 3, :error => 4}

      # Default defined priorities (1 = highest priority)
      PRIORITIES = {:high => 10, :medium => 100, :low => 1000}

      # List of properties for each independent job
      PROPERTIES = %w{runner tries priority planified_at started_at type
         ended_at result_code result_output state name created_at updated_at
         notify_to stored_options result_error}

      # Sets a value for a property
      def set_property(property, value)
        raise NotImplementedError.new("Implement set_property(property, value) in your Job class.")
      end

      # This is the function used to fire the job work.
      def run!
        # Check initial prerequisites
        unless state == STATES[:instantiated] && runner
          raise "Object not correctly instantiated! Use ActiveManager.get to get a job"
        end

        # Initial marking
        set_property :started_at, Time.now.utc
        set_property :tries, self.tries + 1
        set_property :state, STATES[:started]

        # Manage error channel to capture errors
        orig_stderr = STDERR.dup
        new_stderr = Tempfile.new('stderr')
        STDERR.reopen(new_stderr)

        # Call to do the real job work
        result = begin
          do_job_work
        rescue => e
          # log the caught exception
          exception_error = e.inspect + e.backtrace.inspect
          # return an error result code
          -1
        end

        # Update state accordingly to the result
        new_state = if result != 0
          tries >= 3 ? STATES[:error] : STATES[:waiting]
        else
          notify_finished
          STATES[:finished]
        end

        error_log = exception_error || (IO.read(new_stderr.path) rescue "Can't read error log")
        limited_error_log = limit_text_size(error_log, 30000)

        # Final properties update
        set_property :ended_at, Time.now.utc
        set_property :state, new_state
        set_property :result_code, result
        set_property :result_error, limited_error_log

        # Reset to the original error out
        STDERR.reopen(orig_stderr)
        new_stderr.close!
      end

      # This is where the work of a job shall be. Returns a result code (0 if run without errors, !=0 otherwise)
      # Everything thrown through the error channel will be captured
      # The property :result_output can be set to the desired output log
      def do_job_work
        raise NotImplementedError.new("Implement do_job_work() in your Job subclass")
      end

      # Limits the size of a string by the middle, leaving the head and the tail.
      # +max_size+ is the size of the string
      def limit_text_size( text, max_size , options = {})
        options = options.reverse_merge({
            :middle_mark => "\n... truncated content ... \n"
          })
        # To make sure that the result is not bigger than length
        max_size = max_size - options[:middle_mark].size
        if text.size > max_size
          text[0..((max_size/2)-1)] + options[:middle_mark] + text[(max_size/-2)..-1]
        else
          text
        end
      end


      # This module contains all the methods that will be accessible as class
      # methods to the Job subclasses
      module JobClassMethods

        # Time between a failed execution of a job and a retry
        mattr_accessor :retry_interval
        self.retry_interval = 45.seconds

        # Creates a new job and inserts it to the Job Manager,
        # to be run according to the planification options.
        # Returns the created job
        def run_async(options = {})
          UbiquoJobs.manager.add(
            self,
            self.base_default_options.merge(
              self.job_default_options
            ).merge(options)
          )
        end

        # Return a hash with the default options for all jobs
        def base_default_options
          {:priority => PRIORITIES[:low]}
        end

        # This can be overwritten by the final job class to set their own default options
        def job_default_options
          {}
        end

      end
    end
  end
end
