# TODO: Look for a better way to do this (include classmethods and instance methods or at least make clear the intention).
module Ubiquo
  module Extensions
    module ActiveRecord

      def self.extended(klass)
        # create a paginate alias for ubiquo_paginate unless already exists
        alias_method :paginate, :ubiquo_paginate unless klass.respond_to?('paginate')
      end

      # TODO: Make use of alias and add test for it
      def han(args)
        human_attribute_name(args)
      end

      # Applies a limit and offset scope that allows to easily paginate model results
      # options can be the following:
      #   :page => current page (default 1)
      #   :per_page => number of elements per page (default: :elements_per_page in Ubiquo Config)
      #
      # Returns an array composed of
      # [{
      #   :previous => nil or the previous page number
      #   :next => nil or the next page number
      #   },
      #   requested items
      # ]
      def ubiquo_paginate(options = {})
        options.delete_if{|o1,o2| o2.blank? }
        options.reverse_merge!({:page => 1, :per_page => Ubiquo::Config.get(:elements_per_page) })
        items = self.with_scope(:find => {:limit => (options[:per_page].to_i + 1), :offset => (options[:per_page].to_i * (options[:page].to_i - 1))}) do
          yield
        end
        [
         {
           :previous => (options[:page].to_i > 1 ? options[:page].to_i - 1 : nil),
           :next => (items.delete_at(options[:per_page].to_i).nil? ? nil : options[:page].to_i + 1)
         },
         items
        ]
      end


      # Intermediate method customizing paperclip has_attached_file
      # Calls paperclip with id_partition (folders style 000/000/001) in path and url params
      def file_attachment(field, options = {})
        options.reverse_merge!(Ubiquo::Config.get(:attachments))
        visibility = options[:visibility]

        # Comment it because we didn't achieved run path with lambda
        # v = nil
        # path = lambda { |obj|
        #   v = visibility.is_a?(Proc) ? visibility.call(obj.instance) : visibility
        #   v_path = options["#{v}_path".to_sym]
        #   ":rails_root/#{v_path}/media/:attachment/:id_partition/:style/:basename.:extension"
        # }
        Paperclip::Interpolations[:visibility_prefix] = lambda do |attachment, style|
          '/ubiquo/attachment' if attachment.instance.respond_to?(:is_protected) && attachment.instance.is_protected
        end
        path = ":rails_root/#{visibility}/media/:class/:attachment/:id_partition/:style/:filename"
        define_method("#{field}_is_public?") do
          visibility.to_sym == :public
        end
        styles = Marshal.load(Marshal.dump(options[:styles])) || {}
        processors = options[:processors] || [:thumbnail]
        s3 = {:key => '', :secret =>'', :bucket => ''}
        if File.exists?("#{Rails.root}/config/s3.yml")
          s3_config = YAML.load_file("#{Rails.root}/config/s3.yml")
          s3[:key] = s3_config[Rails.env]['access_key_id']
          s3[:secret] = s3_config[Rails.env]['secret_access_key']
          s3[:bucket] = s3_config[Rails.env]['bucket']
        end

        if options[:storage] == :s3
          if s3_config[Rails.env]['s3_host_alias']
            url = ':s3_alias_url'
            s3[:s3_host_alias] = s3_config[Rails.env]['s3_host_alias']
          else
            url = ':s3_domain_url'
          end
          path = "media/:class/:attachment/:id_partition/:style/:filename"
        else
          url = ":visibility_prefix/media/:class/:attachment/:id_partition/:style/:filename"
        end

        has_attached_file field,
          :url => options[:url] || url,
          :path => options[:path] || path,
          :styles => styles,
          :processors => processors,
          :whiny => false,
          :storage => options[:storage] || :filesystem,
          :s3_credentials => {
            :access_key_id => s3[:key],
            :secret_access_key => s3[:secret],
            :bucket => s3[:bucket],
          },
          :s3_host_alias => s3[:s3_host_alias],
          :s3_headers => options[:s3_headers] || {}
      end

      # Function for apply an array of scopes.
      # see self.create_scopes documentation for an example
      def apply_find_scopes(scopes, &initial)
        scopes.compact.inject(initial) do |block, value|
          Proc.new do
            with_scope({:find => value}, &block)
          end
        end.call
      end

      # iterate over filters and stores each returned value in an array.
      # returns an array with all returned values of each iteration.
      # example of usage:
      #
      # scopes = create_scopes(filters) do |filter, value|
      #   case filter
      #   when :string
      #     {:conditions => ["upper(tasks.name) LIKE upper(?) or upper(tasks.description) LIKE upper(?)", "%#{value}%", "%#{value}%"]}
      #   when :time
      #     case value.to_s
      #     when "current"
      #       {:conditions => ["tasks.status < 100"]}
      #     when "old"
      #       {:conditions => ["tasks.status = 100"]}
      #     end
      #   when :project
      #     {:conditions => ["tasks.project_id = ?", value.to_i]}
      #   when :type
      #     {:conditions => ["tasks.task_type_id = ?", value.to_i]}
      #   when :ubiquo_user
      #     {:conditions => ["tasks.owner_id = ?", value.to_i]}
      #   when :current_ubiquo_user
      #     scope_options_for_ubiquo_user(value)
      #   end
      # end
      # apply_find_scopes(scopes) do
      #   find(:all, :include => [:task_type, :owner, {:project => [:owner, :project_permissions]}])
      # end
      def create_scopes(filters)
        filters.inject([]) do |acc, (key, value)|
          next acc if value.nil? || (value.respond_to?(:empty?) ? value.empty? : false)
          scope = yield(key, value)
          acc + [scope]
        end
      end
    end
  end
end
