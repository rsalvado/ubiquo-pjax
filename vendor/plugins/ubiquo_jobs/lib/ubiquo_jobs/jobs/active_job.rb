#
# Class that manages persistency of jobs classes as an ActiveRecord
#
module UbiquoJobs
  module Jobs
    class ActiveJob < ActiveRecord::Base
      include UbiquoJobs::Jobs::JobUtils

      before_create :set_default_state
      before_save :store_options

      has_many :active_job_dependants,
        :foreign_key => 'previous_job_id',
        :class_name => 'UbiquoJobs::Jobs::ActiveJobDependency'

      has_many :active_job_dependencies,
        :foreign_key => 'next_job_id'

      has_many :dependencies,
        :through => :active_job_dependencies,
        :source => :previous_job

      has_many :dependants,
        :through => :active_job_dependants,
        :source => :next_job,
        :dependent => :destroy

      attr_accessor :options

      # Save updated attributes.
      # Optimistic locking is handled automatically by Active Record
      def set_property(property, value)
        update_attribute property, value
      end

      # Returns the outputted results of the job execution, if any
      def output_log
        self.result_output
      end

      # Returns the error messages produced by the job execution, if any
      def error_log
        self.result_error
      end

      # Ubiquo finder method
      # See vendor/plugins/ubiquo_core/lib/extensions/active_record.rb to see an example of usage.
      def self.filtered_search(filters = {}, options = {})

        scopes = create_scopes(filters) do |filter, value|
          case filter
          when :text
            {:conditions => ["upper(name) LIKE upper(?)", "%#{value}%"]}
          when :date_start
            {:conditions => ["created_at > ?", "#{value}"]}
          when :date_end
            {:conditions => ["created_at < ?", "#{value}"]}
          when :state
            {:conditions => ["state = ?", value]}
          when :state_not
            {:conditions => ["state != ?", value]}
          end
        end

        apply_find_scopes(scopes) do
          find(:all, options)
        end
      end

      # Set a job to be executed (again), giving it a planification time
      # Useful e.g. for a stopped job or a job that has not had a succesful
      # execution (is in error state) but you want a retry.
      def reset!
        update_attributes(
          :runner => nil,
          :state => STATES[:waiting],
          :planified_at => Time.now.utc + Base.retry_interval
        )
      end

      protected

      # Set the waiting state as default
      def set_default_state
        self.state ||= STATES[:waiting]
      end

      # Using the configured notifier, send a "finished job" email,
      # if a receiver has been set in notify_to
      def notify_finished
        UbiquoJobs.notifier.deliver_finished_job self unless notify_to.blank?
      end

      def validate_command
        errors.add_on_blank(:command)
        false unless errors.empty?
      end

      # Store the options hash in the stored_options field, in yaml format
      def store_options
        write_attribute :stored_options, self.options.to_yaml
      end

      # Load the stored options (which are stored in yaml) into the options hash
      def after_find
        begin
          self.options = YAML::load(self.stored_options.to_s)
          # Fix for http://dev.rubyonrails.org/ticket/7537
          self.options.each_pair do |k,v|
            resolve_constant v
          end if self.options
          self.options = YAML::load(self.stored_options.to_s)

        rescue
          update_attributes(
            :state => STATES[:error],
            :result_error => $!.inspect + $!.backtrace.inspect + self.stored_options.to_s
          )
        end
      end

      # Looks for and loads unresolved constants recursively
      def resolve_constant(element)
        unless element.instance_variable_get(:@class).nil?
          element.instance_variable_get(:@class).constantize
        end
        if element.is_a?(Array) || element.is_a?(Hash)
          element.each do |val|
            resolve_constant val
          end
        end
      end

    end
  end
end
