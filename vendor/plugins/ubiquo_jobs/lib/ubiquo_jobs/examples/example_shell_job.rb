#
# An example shell job class
# Overrides set_command method using 'path' virtual attribute
# Ex:
#   ExampleShellJob.run_async(:path => '.')
#   UbiquoJobs.manager.get('runner').run! 
# will execute 
#   ls .
# 
module UbiquoJobs
  module Examples
    class ExampleShellJob < UbiquoJobs::Jobs::Base

      include UbiquoJobs::Helpers::ShellJob

      attr_accessor :path

      def set_command
        self.command = 'ls ' + path
      end

    end
  end
end
