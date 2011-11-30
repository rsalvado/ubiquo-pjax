require 'test_helper'

class UbiquoJobs::Examples::ExampleShellJobTest < ActiveSupport::TestCase
  def test_should_create_example_job
    assert create_example_job
  end
  
  def test_should_set_command
    example_job = create_example_job(:path => '.')
    assert_equal 'ls .', example_job.command
  end

  private

  def create_example_job(options = {})
    default_options = {
      :path => '',
      :planified_at => Time.now.utc,
    }
    UbiquoJobs::Examples::ExampleShellJob.run_async(default_options.merge(options))
  end

end
