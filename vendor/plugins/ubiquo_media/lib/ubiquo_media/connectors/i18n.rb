module UbiquoMedia
  module Connectors
    class I18n < Base

      # Validates the ubiquo_i18n-related dependencies
      def self.validate_requirements
        unless Ubiquo::Plugin.registered[:ubiquo_i18n]
          raise ConnectorRequirementError, "You need the ubiquo_i18n plugin to load #{self}"
        end
        [::Asset, ::AssetPublic, ::AssetPrivate, ::AssetRelation].each do |klass|
          if klass.table_exists?
            klass.reset_column_information
            columns = klass.columns.map(&:name).map(&:to_sym)
            unless [:locale, :content_id].all?{|field| columns.include? field}
              if Rails.env.test?
                ::ActiveRecord::Base.connection.change_table(klass.table_name, :translatable => true){}
                klass.reset_column_information
              else
                raise ConnectorRequirementError,
                  "The #{klass.table_name} table does not have the i18n fields. " +
                  "To use this connector, update the table enabling :translatable => true"
              end
            end
          end
        end
      end

      def self.unload!
        [::Asset, ::AssetRelation].each do |klass|
          klass.instance_variable_set :@translatable, nil
          klass.clear_locale_uniqueness_per_entity_validation if klass.respond_to?(:clear_locale_uniqueness_per_entity_validation)
        end
        ::AssetRelation.send :alias_method, :asset, :asset_without_shared_translations
        ::AssetRelation.send :alias_method, :related_object, :related_object_without_shared_translations
      end

      module Asset

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:translatable, :name, :description)
          klass.send(:include, InstanceMethods)
          I18n.register_uhooks klass, ClassMethods, InstanceMethods
        end

        module ClassMethods

          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            filter_locale = filters[:locale] ?
              {:find => {:conditions => ["assets.locale <= ?", filters[:locale]]}} : {}

            with_scope(filter_locale) do
              yield
            end
          end
        end

        module InstanceMethods
          # Performs any necessary step after an update
          # This can be useful to handle the asset special attribute :resource
          def uhook_after_update
            # Updates :resource in translations, if this field has been updated
            if self.class.instance_variable_get('@original_resource_owner').blank?
              begin
                self.class.instance_variable_set('@original_resource_owner', self)
                # The resource we are copying must be saved for paperclip to work correctly
                self.resource.save
                translations.each do |translation|
                  translation.without_updating_translations do
                    translation.resource = self.resource
                    translation.save
                  end
                end
              ensure
                self.class.instance_variable_set('@original_resource_owner', nil)
              end
            end
          end

          # Prepare the instance after being cloned, and still not saved
          def uhook_cloned_object( obj )
            obj.content_id = nil
          end
        end

      end

      module AssetRelation

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:translatable, :name, :position)
          klass.send(:share_translations_for, :asset, :related_object)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods

          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            filter_locale = filters[:locale] ?
              {:find => {:conditions => ["asset_relations.locale <= ?", filters[:locale]]}} : {}

            with_scope(filter_locale) do
              yield
            end
          end
        end
      end

      module UbiquoAssetsController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
          I18n.register_uhooks klass, InstanceMethods
        end

        module Helper
          # Adds a locale filter to the received filter_set
          def uhook_asset_filters filter_set
            filter_set.locale
          end

          # Returns content to show in the sidebar when editing an asset
          def uhook_edit_asset_sidebar asset
            show_translations(asset, :hide_preview_link => true)
          end

          # Returns content to show in the sidebar when creating an asset
          def uhook_new_asset_sidebar asset
            show_translations(asset, :hide_preview_link => true)
          end

          # Returns the available actions links for a given asset
          def uhook_asset_index_actions asset
            actions = []
            if asset.in_locale?(current_locale)
              actions << link_to(t("ubiquo.edit"), edit_ubiquo_asset_path(asset), :class => "btn-edit")
            end

            unless asset.in_locale?(current_locale)
              actions << link_to(
                t("ubiquo.translate"),
                new_ubiquo_asset_path(:from => asset.content_id)
              )
            end

            if asset.in_locale?(current_locale)
              actions << link_to(t("ubiquo.media.advanced_edit"), advanced_edit_ubiquo_asset_path(asset), advanced_edit_link_attributes) if advanced_asset_form_for( asset )
            end

            actions << link_to(t("ubiquo.remove"),
              ubiquo_asset_path(asset, :destroy_content => true),
              :confirm => t("ubiquo.media.confirm_asset_removal"), :method => :delete,
              :class => "btn-delete"
            )

            if asset.in_locale?(current_locale, :skip_any => true)
              actions << link_to(t("ubiquo.remove_translation"), ubiquo_asset_path(asset),
                :confirm => t("ubiquo.media.confirm_asset_removal"), :method => :delete
              )
            end

            actions
          end

          # Returns any necessary extra code to be inserted in the asset form
          def uhook_asset_form form
            (form.hidden_field :content_id) + (hidden_field_tag(:from, params[:from]))
          end
        end

        module InstanceMethods

          # Returns a hash with extra filters to apply
          def uhook_index_filters
            {:locale => params[:filter_locale]}
          end

          # Returns a subject that will have applied the index filters
          # (e.g. a class, with maybe some scopes applied)
          def uhook_index_search_subject
            ::Asset.locale(current_locale, :all)
          end

          # Initializes a new instance of asset.
          def uhook_new_asset
            ::AssetPublic.translate(params[:from], current_locale, :copy_all => true)
          end

          # Performs any required action on asset when in edit
          def uhook_edit_asset asset
            unless asset.in_locale?(current_locale)
              redirect_to(ubiquo_assets_path)
              false
            end
          end

          # Creates a new instance of asset.
          def uhook_create_asset visibility
            asset = visibility.new(params[:asset])
            asset.locale = current_locale
            if params[:from] && asset.resource_file_name.blank?
              asset.resource = visibility.find(params[:from]).resource
            end
            asset
          end

          #destroys an asset instance. returns a boolean that means if the destroy was done.
          def uhook_destroy_asset(asset)
            destroyed = false
            if params[:destroy_content]
              destroyed = asset.destroy_content
            else
              destroyed = asset.destroy
            end
            destroyed
          end
        end
      end

      module Migration

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods
          def uhook_create_assets_table
            create_table :assets, :translatable => true do |t|
              yield t
            end
          end

          def uhook_create_asset_relations_table
            create_table :asset_relations, :translatable => true do |t|
              yield t
            end
          end
        end
      end

      module ActiveRecord
        module Base

          def self.included(klass)
            klass.send(:extend, ClassMethods)
            I18n.register_uhooks klass, ClassMethods
            update_reflections_for_uhook_media_attachment
          end

          # Updates the needed reflections for
          def self.update_reflections_for_uhook_media_attachment
            ClassMethods.module_eval do
              module_function :uhook_media_attachment_process_call
            end
            I18n.get_uhook_calls(:uhook_media_attachment).flatten.each do |call|
              ClassMethods.uhook_media_attachment_process_call call
            end
          end

          module ClassMethods
            # called after a media_attachment has been defined and built
            def uhook_media_attachment field, options
              parameters = {:klass => self, :field => field, :options => options}
              I18n.register_uhook_call(parameters) {|call| call.first[:klass] == self && call.first[:field] == field}
              uhook_media_attachment_process_call parameters
            end

            protected

            def uhook_media_attachment_process_call parameters
              if parameters[:options][:translation_shared]
                field = parameters[:field]
                parameters[:klass].share_translations_for field, :"#{field}_asset_relations"
              end
            end
          end

        end
      end

      def self.prepare_mocks
        add_mock_helper_stubs({
          :show_translations => '', :edit_ubiquo_asset_path => '',
          :new_ubiquo_asset_path => '', :ubiquo_asset_path => '',
          :current_locale => '', :hidden_field_tag => '', :locale => Asset,
          :advanced_asset_form_for => '/'
        })
      end

    end
  end
end
