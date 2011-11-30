module UbiquoJobs
  module Managers
    class Base

      # Get the most appropiate job to run, depending job priorities, states
      # dependencies and planification dates
      # 
      #   runner: name of the worker that is asking for a job
      #
      def self.get(runner)
        raise NotImplementedError.new("Implement get(runner) in your Manager.")
      end
      
      # Get an already assigned task for a given runner,
      # or nil if that runner does not have any assigned task
      # 
      #   runner: name of the worker that is asking for a job
      #
      def self.get_assigned(runner)
        raise NotImplementedError.new("Implement get_assigned(runner) in your Manager.")        
      end

      # Get the job instance that has the given job_id
      # 
      #   job_id: job identifier
      #
      def self.get_by_id(job_id)
        raise NotImplementedError.new("Implement get_by_id(runner) in your Manager.")
      end
      
      # Get an array of jobs matching filters
      # 
      #   filters: hash of properties that the jobs must fullfill, and/or the following options:
      #     {
      #       :order => list order, sql syntax
      #       :page => number of the asked page, for pagination
      #       :per_page => number per_page job elements (default 10)
      #     }
      # Returns an array with the format [pages_information, list_of_jobs]
      #
      def self.list(filters = {})
        raise NotImplementedError.new("Implement get(runner) in your Manager.")
      end
      
      # Creates a job using the given options, and planifies it 
      # to be run according to the planification options.
      # Returns the newly created job
      # 
      #   type: class type of the desired job
      #   options: properties for the new job
      #
      def self.add(type, options = {})
        raise NotImplementedError.new("Implement add(runner) in your Manager.")
      end

      # Deletes a the job that has the given identifier
      # Returns true if successfully deleted, false otherwise
      # 
      #   job_id: job identifier
      #
      def self.delete(job_id)
        raise NotImplementedError.new("Implement delete(job_id) in your Manager.")
      end

      # Updates the existing job that has the given identifier
      # Returns true if successfully updated, false otherwise
      # 
      #   job_id: job identifier
      #   options: a hash with the changed properties
      #
      def self.update(job_id, options)
        raise NotImplementedError.new("Implement update(job_id) in your Manager.")
      end

      # Marks the job with the given identifier to be repeated
      # 
      #   job_id: job identifier
      #
      def self.repeat(job_id)
        raise NotImplementedError.new("Implement repeat(job_id) in your Manager.")
      end

      # Return the job class that the manager is using, as a constant
      # 
      #   type: class type of the desired job
      #   options: properties for the new job
      #
      def self.job_class
        raise NotImplementedError.new("Implement job_class() in your Manager.")
      end
    end
  end
end
