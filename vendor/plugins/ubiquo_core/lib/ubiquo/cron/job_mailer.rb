module Ubiquo
  module Cron

    # Sends mail with cron job errors.
    class JobMailer < ActionMailer::Base

      def self.reloadable?() false end

      self.template_root = "#{File.dirname(__FILE__)}/views"

      # Sends email with cron job error.
      #
      # ==== Attributes
      #
      # * +error_recipients+ - who to mail.
      # * +job+ - job (task) name.
      # * +execution_message+ - string with information about
      #   execution of the job.
      # * +error_message- string with the error message.
      def error(error_recipients, job, execution_message, error_message, sent_at = Time.now)
        app_name = Ubiquo::Config.get(:app_name)
        content_type "text/plain"
        charset 'utf-8'
        recipients error_recipients
        from Ubiquo::Config.get(:notifier_email_from)
        sent_on sent_at
        subject "[#{app_name} #{Rails.env} CRON JOB ERROR] for job: #{job}"
        body(
          :job               => job,
          :application       => app_name,
          :error_message     => error_message,
          :execution_message => execution_message
        )
      end

      private

      def app_name
        Ubiquo::Config.get(:app_name)
      end

    end
  end
end
