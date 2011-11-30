require File.dirname(__FILE__) + "/../../../test_helper.rb"

class UbiquoJobs::Jobs::BaseTest < ActiveSupport::TestCase

  EXPECTED_PROPERTY_LIST = %w{runner tries priority planified_at started_at type 
    ended_at result_code result_output state name created_at 
    updated_at notify_to stored_options result_error}

  def test_should_access_interval
    assert_not_nil UbiquoJobs::Jobs::Base.retry_interval
    UbiquoJobs::Jobs::Base.retry_interval = 40.seconds
    assert_equal 40.seconds, UbiquoJobs::Jobs::Base.retry_interval
  end
  
  def test_should_have_expected_properties
    assert_equal_set EXPECTED_PROPERTY_LIST, UbiquoJobs::Jobs::Base::PROPERTIES
  end
  
  def test_should_have_default_low_priority
    job_type = create_job_type
    assert_equal(
      {:priority => UbiquoJobs::Jobs::Base::PRIORITIES[:low]},
      job_type.base_default_options
    )
  end

  def test_should_run_async
    job_type = create_job_type
    options = job_type.base_default_options
    UbiquoJobs.manager.expects(:add).with(job_type, options)
    job_type.run_async
  end
  
  def test_should_run_async_with_correct_options
    job_type = create_job_type
    correct_options = {:a => 'a', :b => 'b'}
    job_type.expects(:base_default_options).returns({:a => 'n'})
    job_type.expects(:job_default_options).returns({:a => 'a', :b => 'n'})
    UbiquoJobs.manager.expects(:add).with(job_type, correct_options)
    job_type.run_async(:b => 'b')
  end

  private

  def create_job_type
    Class.new.send(:include, UbiquoJobs::Jobs::JobUtils)
  end
  
end
