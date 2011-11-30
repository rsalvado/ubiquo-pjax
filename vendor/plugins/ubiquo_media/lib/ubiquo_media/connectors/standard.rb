module UbiquoMedia
  module Connectors
    class Standard < Base


      module Asset

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:include, InstanceMethods)
          Standard.register_uhooks klass, ClassMethods, InstanceMethods
        end

        module ClassMethods
          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            yield
          end
        end

        module InstanceMethods
          # Performs any necessary step after an update
          # This can be useful to handle the asset special attribute :resource
          def uhook_after_update
          end

          # Prepare the instance after being cloned, and still not saved
          def uhook_cloned_object( obj )
          end
        end

      end

      module AssetRelation

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            yield
          end
        end

      end


      module UbiquoAssetsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
          Standard.register_uhooks klass, InstanceMethods
        end

        module Helper
          # Receives a filter_set to add extra filters
          def uhook_asset_filters filter_set
          end

          # Returns content to show in the sidebar when editing an asset
          def uhook_edit_asset_sidebar asset
            ''
          end

          # Returns content to show in the sidebar when creating an asset
          def uhook_new_asset_sidebar asset
            ''
          end

          # Returns the available actions links for a given asset
          def uhook_asset_index_actions asset
            actions = [
              link_to(t('ubiquo.edit'), edit_ubiquo_asset_path(asset), :class => 'btn-edit'),
              link_to(t('ubiquo.remove'), ubiquo_asset_path(asset), :confirm => t('ubiquo.media.confirm_asset_removal'), :method => :delete, :class => 'btn-delete'),
            ]
            actions << link_to(t('ubiquo.media.advanced_edit'), advanced_edit_ubiquo_asset_path(asset),advanced_edit_link_attributes) if asset.is_resizeable?
            actions
          end

          # Returns any necessary extra code to be inserted in the asset form
          def uhook_asset_form form
            ''
          end
        end

        module InstanceMethods

          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {}
          end

          # Returns a subject that will have applied the index filters
          # (e.g. a class, with maybe some scopes applied)
          def uhook_index_search_subject
            ::Asset
          end

          # Initializes a new instance of asset.
          def uhook_new_asset
            ::AssetPublic.new
          end

          # Performs any required action on asset when in edit
          # Edit action will not continue if this hook returns false
          def uhook_edit_asset asset
            true
          end

          # Creates a new instance of asset.
          def uhook_create_asset visibility
            visibility.new(params[:asset])
          end

         #destroys an asset instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_asset(asset)
            asset.destroy
          end
        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          Standard.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_create_assets_table
            create_table :assets do |t|
              yield t
            end
          end

          def uhook_create_asset_relations_table
            create_table :asset_relations do |t|
              yield t
            end
          end
        end
      end

      module ActiveRecord
        module Base

          def self.included(klass)
            klass.send(:extend, ClassMethods)
            Standard.register_uhooks klass, ClassMethods
          end

          module ClassMethods
            # called after a media_attachment has been defined and built
            def uhook_media_attachment field, options
              parameters = {:klass => self, :field => field, :options => options}
              Standard.register_uhook_call parameters
            end
          end

        end
      end

      def self.prepare_mocks
        add_mock_helper_stubs({
          :edit_ubiquo_asset_path => '', :ubiquo_asset_path => '',
        })
      end
    end
  end
end
