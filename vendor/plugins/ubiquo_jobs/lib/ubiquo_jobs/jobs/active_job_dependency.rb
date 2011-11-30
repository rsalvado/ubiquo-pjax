module UbiquoJobs
  module Jobs
    class ActiveJobDependency < ActiveRecord::Base

      belongs_to :previous_job, 
        :class_name => "UbiquoJobs::Jobs::ActiveJob", 
        :foreign_key => "previous_job_id"

      belongs_to :next_job, 
        :class_name => "UbiquoJobs::Jobs::ActiveJob", 
        :foreign_key => "next_job_id"

    end
  end
end