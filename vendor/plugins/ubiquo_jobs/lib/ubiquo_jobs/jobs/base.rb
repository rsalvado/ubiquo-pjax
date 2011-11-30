module UbiquoJobs
  module Jobs

    #
    # All Job classes must inherit from this class
    # 
    class Base < UbiquoJobs.manager.job_class
      include UbiquoJobs::Jobs::JobUtils
    end

  end
end
