module Ubiquo
  module Cron

    # Allows to manage a user's crontab in the context of an ubiquo
    # application.
    class Crontab

      include Singleton

      # e-mail adress to notify when some error happens. Defaults to nil
      attr_accessor  :mailto
      # Application path. Defaults to Rails.root
      attr_accessor  :path
      # Environment to set when running jobs. Defaults to Rails.env
      attr_accessor  :env
      # Full path to the filename to use for logs.
      attr_accessor  :logfile

      # Alias to schedule instance method
      def self.schedule(*args, &block)
        self.instance.schedule(*args, &block)
      end

      # Adds a rake task to the crontab schedule.
      #
      # ==== Attributes
      #
      # * +schedule+ - When to run the task in cron syntax
      # * +task+ - Name of the rake task and needed parameters
      #
      # ==== Examples
      #
      #  # Executes the update:statistics (rake) task every minute and
      #  # logs debug information.
      #  cron.rake   "* * * * *", "update:statistics debug='true'"
      def rake(schedule, task)
        job, params = task.split(' ', 2)
        @lines.push <<-eos.gsub(/^ {10}/, '').gsub("\n", ' ').strip
          #{schedule} /bin/bash -l -c "cd #{self.path}
          && RAILS_ENV=#{self.env}
          rake ubiquo:cron:runner task='#{job}' #{params} --silent 2>&1"
        eos
      end

      # Adds a script/runner like task to the crontab schedule.
      #
      # ==== Attributes
      #
      # * +schedule+ - When to run the job in cron syntax.
      # * +code+ - Code to execute.
      #
      # ==== Examples
      #
      #  # Executes the User.notify_all method every minute and
      #  # logs debug information.
      #  cron.runner   "* * * * *", "User.notify_all"
      def runner(schedule, task)
        @lines.push <<-eos.gsub(/^ {10}/, '').gsub("\n", ' ').strip
          #{schedule} /bin/bash -l -c "cd #{self.path}
          && RAILS_ENV=#{self.env}
          rake ubiquo:cron:runner task='#{task}' type='script' --silent 2>&1"
        eos
      end

      # Adds a free form command to the crontab schedule.
      #
      # ==== Attributes
      #
      # * +schedule+ - When to run the job in cron syntax.
      # * +task+ - Your command.
      #
      # ==== Examples
      #
      #  # Runs a vacuum of a postgres database.
      #  cron.command   "@daily", "vacuumdb --all --analyze -q"
      def command(schedule, command)
        @lines << "#{schedule} #{command}"
      end

      # Adds a comment line to crontab.
      #
      #  cron.comment "This is a comment."
      def comment(comment)
        @lines << "### #{comment} ###"
      end

      # Renders a string representation of the current crontab
      # schedule.
      def render
        just_comments? ? "" : @lines.join("\n")
      end

      # This methods installs the defined schedule in crontab
      # ovewriting the one installed for the user running this method.
      def install!
        schedule = render
        unless schedule.blank?
          file = Tempfile.new('schedule')
          file << schedule
          file.close
          status = system("crontab",file.path)
        else
          status = 0
        end
        status
      ensure
        file.delete if file
      end

      # Allows to define and configure a user's crontab.
      #
      # ==== Attributes =====
      #
      # * +namespace+ - Add start and end comments with the defined
      #                 string.
      # * +&block+ - Receives a crontab instance to define the
      #              schedule on.
      #
      # ==== Example ====
      #
      #  Ubiquo::Cron::Crontab.schedule('myapp') do |cron|
      #    cron.mailto  = 'errors@foobar.com'
      #    cron.rake    "* * * * *", "update:statistics"
      #    cron.runner  "* * * * *", "User.notify_all"
      #    cron.command "@daily",    "vacuum --all --analyze -q"
      #  end
      def schedule(namespace = 'application', &block)
        comment "Start jobs for #{namespace}"
        block.call(self)
        comment "End jobs for #{namespace}"
        self
      end

      private

      def initialize
        @mailto   = nil
        @path     = Rails.root
        @env      = Rails.env
        @logfile  = File.join Rails.root, 'log', "cron-#{@env}.log"
        @lines    = []
      end

      # Returns true if all crontab lines are comments
      def just_comments?
        @lines.inject(true) do |result, line|
          result && line.match(/^#/)
        end
      end

      # Helper method to reset the instance when testing
      def reset!
        initialize
        self
      end

    end
  end
end
