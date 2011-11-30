#
# An example job class
# It simply calculates a Array.size, overriding do_job_work
# Passes the required arguments using the options hash
# Ex:
#   ExampleJob.run_async(:options => {:set => [1,2]})
#   UbiquoJobs.manager.get('runner').run! 
# will execute 
#   Model.count
# to display the results use job.output_log
# 
module UbiquoJobs
  module Examples
    class ExampleJob < UbiquoJobs::Jobs::Base

      def do_job_work
        set_property :result_output, self.options[:set].size
        return 0
      end

    end
  end
end