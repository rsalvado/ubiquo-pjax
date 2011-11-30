require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Cron::JobMailerTest < ActionMailer::TestCase

  test "Job error notification" do
    app_name = Ubiquo::Config.get(:app_name)
    job = 'mailer_test'
    to = 'receiver@test.com'
    execution_message = 'execution_message'
    error_message = 'error_message'

    @expected.from = Ubiquo::Config.get(:notifier_email_from)
    @expected.to = to
    @expected.subject = "[#{app_name} #{Rails.env} CRON JOB ERROR] for job: #{job}"
    @expected.body = "An error has ocurred while executing #{job} cron job for #{app_name} application. Additional information below:\n\nExecution log message:\n#{execution_message}\n\nError message backtrace:\n#{error_message}\n"
    @expected.date = Time.now

    assert_equal @expected.encoded, JobMailer.create_error(@expected.to, job, execution_message, error_message, @expected.date).encoded
  end

end
