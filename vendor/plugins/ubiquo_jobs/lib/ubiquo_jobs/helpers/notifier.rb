module UbiquoJobs
  module Helpers
    class Notifier
  
      # Method called whenever a job is finished
      def finished_task(task)
        raise NotImplementedError.new("Implement finished_task(task) in your JobNotifier subclass")
      end

    end
  end
end
