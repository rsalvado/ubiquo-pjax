require File.dirname(__FILE__) + '/../../test_helper'

class Ubiquo::JobsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:jobs)
  end

  def test_should_get_history
    job_1 = create_job()
    job_2 = create_job(:state => UbiquoJobs::Jobs::Base::STATES[:finished])
    get :history
    assert_response :success
    assert_not_nil assigns(:jobs)
    assert assigns(:jobs).include?(job_2)
    assert !assigns(:jobs).include?(job_1)
  end

  def test_should_update_job
    job = create_job
    put :update, :id => job.id, :job => {:priority => 2}
    assert_redirected_to ubiquo_jobs_path
    assert_equal 2, job.reload.priority
  end

  def test_should_repeat_job
    job = create_job
    put :repeat, :id => job.id
    assert_redirected_to ubiquo_jobs_path
    assert_equal UbiquoJobs::Jobs::Base::STATES[:waiting], job.reload.state
  end

  def test_should_get_job_output
    job = create_job
    get :output, :id => job.id
    assert_response :success
    assert_equal UbiquoJobs::Jobs::Base::STATES[:waiting], job.reload.state
  end

  def test_should_destroy_job
    job = create_job
    UbiquoJobs::manager.expects(:delete).with(job.id.to_s)
    delete :destroy, :id => job.id
    assert_redirected_to ubiquo_jobs_path
  end
  
  private

  def job_attributes(options = {})
    default_options = {
      :priority => 1000 # Default value when using run_async
    }
    default_options.merge(options)  
  end

  def create_job(options = {})
    UbiquoJobs.manager.add(UbiquoJobs.manager.job_class, job_attributes(options))
  end
      
end
