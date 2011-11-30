require 'test_helper'

class UbiquoJobs::Helpers::ShellJobTest < ActiveSupport::TestCase
  def test_should_create_shell_job
    assert create_job
  end
  
  def test_should_not_fail_if_nobody_sets_command
    assert_raise NotImplementedError do
      create_job(:command => nil)
    end
  end

  def test_should_run_job
    create_job
    job = UbiquoJobs.manager.get('me')
    job.run!
    assert_not_equal UbiquoJobs::Jobs::Base::STATES[:started], job.state
    assert job.ended_at >= job.started_at
    assert_equal 1, job.tries
  end  

  def test_should_run_error_job
    create_job(:command => 'errorize')
    job = UbiquoJobs.manager.get('me')
    job.run!
    assert_equal UbiquoJobs::Jobs::Base::STATES[:waiting], job.state
    assert_not_equal 0, job.result_code
    assert_equal 1, job.tries
  end

  def test_should_delay_error_job

    old_job = create_job(:command => 'errorize')
    assert_equal old_job, UbiquoJobs.manager.get('me')
    old_job.reload.run!
    assert_nil UbiquoJobs.manager.get('me')
    future = Time.now.utc + 2.hours
    Time.any_instance.expects(:utc).at_least(1).returns(future)
    assert_equal old_job, UbiquoJobs.manager.get('me')

  end

  def test_should_run_valid_job
    create_job(:command => 'ls')
    job = UbiquoJobs.manager.get('me')
    job.run!
    assert_equal UbiquoJobs::Jobs::Base::STATES[:finished], job.state
    assert_equal 0, job.result_code
  end
  
  def test_should_discard_after_three_attempts

    job = create_job(:command => 'errorize', :tries => 2)
    assert_equal job, UbiquoJobs.manager.get('me')
    job.reload.run!
    assert_nil UbiquoJobs.manager.get('me')
    future = Time.now.utc + 2.hours
    Time.any_instance.expects(:utc).at_least(1).returns(future)
    assert_nil UbiquoJobs.manager.get('me')
    assert_equal UbiquoJobs::Jobs::Base::STATES[:error], job.state

  end
    
  def test_should_get_output_log
    create_job(:command => "echo 'this'")
    job = UbiquoJobs.manager.get('me')
    job.run!
    assert_equal 'this', job.output_log.chomp
  end

  def test_should_get_error_log
    create_job(:command => "echo 'this' 1>&2")
    job = UbiquoJobs.manager.get('me')
    job.run!
    assert_equal 'this', job.error_log.chomp
  end
  
  def test_should_escape_shell_parameter
    job = create_job
    assert_equal 't\"c\?a\\\'.', job.send('escape_sh','t"c?a\'.')
    assert_equal '/some/path', job.send('escape_sh','/some/path')
  end

  def test_should_notificate
    create_job(:notify_to => 'test@test.com')
    job = UbiquoJobs.manager.get('me')
    UbiquoJobs.notifier.expects(:deliver_finished_job).with(job).returns(nil)
    job.run!
  end
  
  def test_should_not_call_callbacks
    job = create_job
    job.expects(:before_execution).never
    job.expects(:after_execution).never
    UbiquoJobs.manager.get('me').run!
  end

  def test_should_call_callbacks_if_exists
    create_job
    job = UbiquoJobs.manager.get('me')
    job.stubs(:before_execution).once.returns(true)
    job.stubs(:after_execution).once.returns(true)
    job.run!
  end

  private

  def create_job(options = {})
    shell_job_class = UbiquoJobs::Jobs::Base.send(:include, UbiquoJobs::Helpers::ShellJob)
    default_options = {
      :command => 'ls',
      :planified_at => Time.now.utc,
    }
    shell_job_class.run_async(default_options.merge(options))
  end
  
end
