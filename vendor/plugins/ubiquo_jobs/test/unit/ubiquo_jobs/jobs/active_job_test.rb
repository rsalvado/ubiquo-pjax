require File.dirname(__FILE__) + "/../../../test_helper.rb"
require 'mocha'

class UbiquoJobs::Jobs::ActiveJobTest < ActiveSupport::TestCase
  
  ActiveJob = UbiquoJobs::Jobs::ActiveJob
  ActiveManager = UbiquoJobs::Managers::ActiveManager
  
  def test_should_create_job
    assert_difference 'ActiveJob.count' do
      job = create_job
      assert !job.new_record?, "#{job.errors.full_messages.to_sentence}"
    end
  end
  
  def test_should_create_with_waiting_state
    job = create_job
    assert_equal UbiquoJobs::Jobs::Base::STATES[:waiting], job.state    
  end
    
  def test_should_access_properties
    job = create_job
    ActiveJob::PROPERTIES.each do |property|
      assert job.respond_to?("#{property}=")
      assert job.respond_to?("#{property}")
    end
  end

  def test_should_update_property_values
    job = create_job
    ActiveJob::PROPERTIES.each do |property|
      job.expects("update_attribute").with(property.to_sym, 0)
      job.set_property(property.to_sym, 0)
    end
  end

  def test_should_stale_jobs
    ActiveJob.delete_all
    job = create_job
    job_bis = ActiveJob.first
    job_bis.update_attribute(:state, 2)
    assert_raise ActiveRecord::StaleObjectError do
      job.update_attribute(:state, 3)
    end
  end
  
  def test_should_not_run_if_not_instantiated
    job = create_job
    assert_raise RuntimeError do
      job.run!
    end
  end
    
  def test_should_filter_by_name
    create_job(:name => "I don't appear")
    assert_equal [], ActiveJob.filtered_search({:text => "notsocommon"})
    job = create_job(:name => "this is a notsocommon word")
    assert_equal_set [job], ActiveJob.filtered_search({:text => "notsocommon"})
  end

  def test_should_filter_by_date_start
    job = create_job()
    job.update_attribute(:created_at, 1.year.from_now)
    assert_equal [], ActiveJob.filtered_search({:date_start => 2.years.from_now})
    job.update_attribute(:created_at, 3.years.from_now)
    assert_equal_set [job], ActiveJob.filtered_search({:date_start => 2.years.from_now})
  end

  def test_should_filter_by_date_end
    job = create_job()
    job.update_attribute(:created_at, 1.years.ago)
    assert_equal [], ActiveJob.filtered_search({:date_end => 2.years.ago})
    job.update_attribute(:created_at, 3.years.ago)
    assert_equal_set [job], ActiveJob.filtered_search({:date_end => 2.years.ago})
  end

  def test_should_filter_by_state
    ActiveJob.delete_all
    job = create_job(:state => 1)
    assert_equal [], ActiveJob.filtered_search({:state => 0})
    assert_equal_set [job], ActiveJob.filtered_search({:state => 1})
  end

  def test_should_filter_by_state_not
    ActiveJob.delete_all
    job_1 = create_job(:state => 1)
    job_2 = create_job(:state => 2)
    assert_equal [job_1, job_2], ActiveJob.filtered_search({:state_not => 0})
    assert_equal [job_2], ActiveJob.filtered_search({:state_not => 1})
  end

  def test_should_wait_for_single_dependency
    ActiveJob.delete_all
    job_1 = create_job(:priority => 1)
    job_2 = create_job(:priority => 5)
    job_1.dependencies << job_2
    assert_equal job_2, ActiveManager.get('me')
    assert_nil ActiveManager.get('you')
    job_2.reload.update_attribute :state, UbiquoJobs::Jobs::Base::STATES[:finished]
    assert_equal job_1, ActiveManager.get('me')
  end

  def test_should_wait_for_dependencies
    ActiveJob.delete_all

    # building jobs and dependencies
    job_1 = create_job
    job_2 = create_job
    job_3 = create_job
    job_4 = create_job
    job_1.dependencies << job_2
    job_1.dependencies << job_3
    job_3.dependencies << job_2
    job_4.dependants << job_3
    job_4.dependants << job_2

    # 4 is the only one without dependencies
    assert_equal job_4, ActiveManager.get('me')
    assert_nil ActiveManager.get('you')
    job_4.reload.update_attribute :state, UbiquoJobs::Jobs::Base::STATES[:finished]
    
    # 3 can't trigger until 2
    assert_equal job_2, ActiveManager.get('me')
    assert_nil ActiveManager.get('you')
    job_2.reload.update_attribute :state, UbiquoJobs::Jobs::Base::STATES[:finished]
    
    # job_3 turn, then 1 can run
    assert_equal job_3, ActiveManager.get('me')
    assert_nil ActiveManager.get('you')
    job_3.reload.update_attribute :state, UbiquoJobs::Jobs::Base::STATES[:finished]
    assert_equal job_1, ActiveManager.get('me')
  end
  
  def test_should_store_options
    create_job(:planified_at => nil)
    options = {
      :string => 'String',
      :number => 1,
      :time => Time.now,
      :model => ActiveJob.first,
      :hash => {:hash => 'Hash'}
    }
    job = create_job({:options => options})
    assert_equal options, job.options 
    assert_equal options.to_yaml, job.stored_options
    assert_equal options, ActiveManager.get('me').options
  end
    
  private

  def create_job(options = {})
    default_options = {
      :priority => 1000, # Default value when using run_async
      :command => 'ls',
      :planified_at => Time.now.utc,
    }
    ActiveJob.create(default_options.merge(options))
  end
  
end
