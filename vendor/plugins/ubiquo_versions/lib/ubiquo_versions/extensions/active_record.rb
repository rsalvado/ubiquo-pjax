module UbiquoVersions
  module Extensions
    module ActiveRecord

      def self.append_features(base)
        super
        base.extend(ClassMethods)
        base.send :include, InstanceMethods
      end
      
      module ClassMethods
        
        # Class method for ActiveRecord that states that a model is versionable
        #
        # EXAMPLE:
        #
        #   versionable :max_amount => 5
        # 
        # possible options:
        #   :max_amount => number of versions that will be stored as a maximum. 
        #                  When this limit is reached, the system starts 
        #                  deleting older versions as required
        #
        
        def versionable(options = {})
          @versionable = true
          @versionable_options = options
          # version_number should not be copied between instances if a model is translatable
          if respond_to?(:add_translatable_attributes) 
            add_translatable_attributes(:version_number, :is_current_version, :parent_version)
          end
          
          # version_number constitute a translatable scope (should not update old versions)
          if respond_to?(:add_translatable_scope) 
            add_translatable_scope(
              lambda do |element|
                condition = sanitize_sql_for_conditions ["#{self.table_name}.is_current_version = ?", true]
                # a new version record with old information doesn't have related translations
                condition += " AND 1=0 " unless element.is_current_version
                condition
              end
            )
          end
          named_scope :versions, lambda{ |version|
            @find_versions_from_version = version
            {}
          }

          # Apply versions named scope to any possible already loaded subclass
          subclasses.each do |klass|
            klass.scopes[:versions] = scopes[:versions]
          end

          define_method("versions") do
            self.class.versions(self)
          end
          
          define_method('restore') do |old_version_id|
            old_version = self.class.find(old_version_id, :version => :all)
            restored_attributes = old_version.instance_variable_get('@attributes')
            self.update_attributes restored_attributes.merge(:is_current_version => true)
          end
        end

        # Adds :current_version => true to versionable models unless explicitly said :version option
        def find_with_current_version(*args)
          if @versionable
            from_version = @find_versions_from_version
            @find_versions_from_version = nil
            options = args.extract_options!
            prepare_options_for_version!(options, from_version)
            
            find_without_current_version(args.first, options)
          else
            find_without_current_version(*args)
          end
        end
        
        # Adds :current_version => true to versionable models unless explicitly said :version option
        def count_with_current_version(*args)
          if @versionable
            from_version = @find_versions_from_version
            @find_versions_from_version = nil
            options = args.extract_options!
            prepare_options_for_version!(options, from_version)
            
            count_without_current_version(args.first || :all, options)
          else
            count_without_current_version(*args)
          end

        end

        # Alias for AR functions when is extended with this module
        def self.extended(klass)
          klass.class_eval do
            class << self
              alias_method_chain :find, :current_version
              alias_method_chain :count, :current_version
            end
          end
        end
        
        # Given a set of "find" options, this method will update it as follows:
        #   if a :version option exists, and is an integer, a :version_number condition will be added
        #   if a :version option exists, and the value :all, a condition to filter by
        #     version will not be added
        #   by default, a condition to find by :is_current_version = true is added. 
        #   
        #   If the from_version attribute is an instance of this model, it will look for versions created with
        #   from_version as the original version.
        #
        def prepare_options_for_version!(options, from_version)
          v = options.delete(:version)
          
          case v
          when Fixnum
            options[:conditions] = merge_conditions(options[:conditions], {:version_number => v})
          when :all
            # do nothing...
          else # not an expected version set. Acts as :last
            unless from_version
              options[:conditions] = merge_conditions(options[:conditions], {:is_current_version => true})
            else
              options[:conditions] = merge_conditions(options[:conditions], 
                ["#{self.table_name}.content_id = ? AND #{self.table_name}.id != ? AND #{self.table_name}.parent_version = ?", 
                  from_version.content_id, 
                  from_version.id,
                  from_version.parent_version
                ]
              )
            end
          end
          options
        end
        
        # Used to execute a block that would create a version without this effect
        # Note that it will disable versionable just for one time, so the block
        # should only contain one versionable-firing event
        def without_versionable
          @versionable_disabled = true
          yield
        end

      end
      
      module InstanceMethods
        
        def self.included(klass)
          klass.alias_method_chain :create, :version_info
          klass.alias_method_chain :update, :version
          klass.alias_method_chain :delete, :all_versions
          klass.alias_method_chain :destroy, :all_versions
        end
        
        # proxy to add a new content_id if empty on creation
        def create_with_version_info
          if self.class.instance_variable_get('@versionable')
            if disable_versionable_once
              create_without_version_info
              return
            end
            unless self.content_id
              self.content_id = self.class.connection.next_val_sequence("#{self.class.table_name}_$_content_id")
            end
            unless self.version_number
              self.version_number = next_version_number
              self.is_current_version = true
            end
            create_without_version_info

            unless self.parent_version
              self.class.without_versionable {update_attribute :parent_version, self.id}
            end
          else
            create_without_version_info
          end
        end
        
        # proxy to add a create a new version when an update is performed
        def update_with_version
          if self.class.instance_variable_get('@versionable') && self.changed?
            if disable_versionable_once
              update_without_version
              return
            end
            self.version_number = next_version_number
            create_new_version
            update_without_version
          else
            update_without_version
          end
        end
        
        # This function looks for other instances sharing the same content_id and is_current_version = true,
        # and creates a new version for them too.
        # This is useful if for any reason you have more than one current version per content_id
        def create_version_for_other_current_versions
          self.class.all(
            :conditions => ["content_id = ? AND is_current_version = ? AND id != ?", self.content_id, true, self.id || 0]
          ).each do |current_version|
            current_version.create_new_version(true)
          end
        end

        # This function creates a new old version of the current instance by cloning it
        def create_new_version(add_version_number = false)
          current_instance = self.class.find(self.id).clone
          current_instance.is_current_version = false
          current_instance.parent_version = self.id
          current_instance.version_number = next_version_number if add_version_number
          current_instance.save
          # delete the older versions if there are too many versions (as defined by max_amount)
          if max_amount = self.class.instance_variable_get('@versionable_options')[:max_amount]
            versions_by_number = self.versions.sort {|a,b| a.version_number <=> b.version_number}
            (versions_by_number.size - max_amount).times do |i|
              versions_by_number[i].delete
            end
          end
        end

        # proxy to destroy all the related versions on destroy
        def destroy_with_all_versions
          if self.class.instance_variable_get('@versionable') && self.is_current_version
            self.versions.destroy_all
          end
          destroy_without_all_versions
        end

        # proxy to delete all the related versions on delete
        def delete_with_all_versions
          if self.class.instance_variable_get('@versionable') && self.is_current_version
            self.versions.delete_all
          end
          delete_without_all_versions
        end

        # This method disables versionable for one action
        def disable_versionable_once
          if self.class.instance_variable_get('@versionable_disabled')
            self.class.instance_variable_set('@versionable_disabled', false)
            true
          end
        end

        # Note that every time that is called, a version number is assigned
        def next_version_number
          self.class.connection.next_val_sequence("#{self.class.table_name}_$_version_number")
        end

      end

    end
  end
end
