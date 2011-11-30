module UbiquoCategories
  module Connectors
    class I18n < Base

      # Validates the ubiquo_i18n-related dependencies
      # Returning false will halt the connector load
      def self.validate_requirements
        unless Ubiquo::Plugin.registered[:ubiquo_i18n]
          unless Rails.env.test?
            raise ConnectorRequirementError, "You need the ubiquo_i18n plugin to load #{self}"
          else
            return false
          end
        end
        if ::Category.table_exists?
          category_columns = ::Category.columns.map(&:name).map(&:to_sym)
          unless [:locale, :content_id].all?{|field| category_columns.include? field}
            if Rails.env.test?
              ::ActiveRecord::Base.connection.change_table(:categories, :translatable => true){}
              if ::ActiveRecord::Base.connection.class.included_modules.include?(Ubiquo::Adapters::Mysql)
                # "Supporting" DDL transactions for mysql
                ::ActiveRecord::Base.connection.begin_db_transaction
                ::ActiveRecord::Base.connection.create_savepoint
              end
              ::Category.reset_column_information
            else
              raise ConnectorRequirementError,
              "The categories table does not have the i18n fields. " +
                "To use this connector, update the table enabling :translatable => true"
            end
          end
        end
      end

      def self.unload!
        [::Category].each do |klass|
          klass.instance_variable_set :@translatable, nil
          klass.clear_locale_uniqueness_per_entity_validation if klass.respond_to?(:clear_locale_uniqueness_per_entity_validation)
        end
      end

      module Category

        def self.included(klass)
          klass.send(:extend, ClassMethods)
          klass.send(:translatable, :name, :description)
          I18n.register_uhooks klass, ClassMethods
        end

        module ClassMethods

          # Returns a condition to return categories using their +identifiers+
          def uhook_category_identifier_condition identifiers, association
            ["#{::Category.alias_for_association(association)}.content_id IN (?)", identifiers]
          end

          def uhook_join_category_table_in_category_conditions_for_sql
            true
          end

          # Applies any required extra scope to the filtered_search method
          def uhook_filtered_search filters = {}
            create_scopes(filters) do |filter, value|
              case filter
              when :locale
                {:conditions => {:locale => value}}
              end
            end
          end

          # Initializes a new category with the given +name+ and +options+
          def uhook_new_from_name name, options = {}
            ::Category.new(
              :name => name,
              :locale => (options[:locale] || :any).to_s,
              :parent_id => options[:parent_id]
            )
          end
        end

      end

      module CategorySet

        def self.included(klass)
          klass.send(:include, InstanceMethods)
          I18n.register_uhooks klass, InstanceMethods
        end

        module InstanceMethods
          # Returns an identifier value for a given +category_name+ in this set
          def uhook_category_identifier_for_name category_name
            self.select_fittest(category_name).content_id rescue 0
          end

          # Returns the fittest category in the requested locale
          def uhook_select_fittest category, options = {}
            options[:locale] ? (category.in_locale(options[:locale]) || category) : category
          end
        end

      end

      module UbiquoCategoriesController
        def self.included(klass)
          klass.send(:include, InstanceMethods)
          klass.send(:helper, Helper)
          I18n.register_uhooks klass, InstanceMethods
        end

        module Helper

          def uhook_category_filters(filter_set)
            filter_set.locale
          end

          # Returns content to show in the sidebar when editing a category
          def uhook_edit_category_sidebar category
            show_translations(category, :hide_preview_link => true)
          end

          # Returns content to show in the sidebar when creating a category
          def uhook_new_category_sidebar category
            show_translations(category, :hide_preview_link => true)
          end

          # Returns the available actions links for a given category
          def uhook_category_index_actions category_set, category
            actions = []
            if category.in_locale?(current_locale)
              actions << link_to(t("ubiquo.view"), [:ubiquo, category_set, category])
            end

            if category.in_locale?(current_locale)
              actions << link_to(t("ubiquo.edit"), [:edit, :ubiquo, category_set, category], :class => 'btn-edit')
            end

            unless category.in_locale?(current_locale)
              actions << link_to(
                t("ubiquo.translate"),
                new_ubiquo_category_set_category_path(
                  :from => category.content_id
                  )
                )
            end

            actions << link_to(t("ubiquo.remove"),
              ubiquo_category_set_category_path(category_set, category, :destroy_content => true),
              :confirm => t("ubiquo.category.index.confirm_removal"), :method => :delete, :class => 'btn-delete'
              )

            if category.in_locale?(current_locale, :skip_any => true) && !category.translations.empty?
              actions << link_to(t("ubiquo.remove_translation"), [:ubiquo, category_set, category],
                :confirm => t("ubiquo.category.index.confirm_removal"), :method => :delete
                )
            end

            actions
          end

          # Returns any necessary extra code to be inserted in the category form
          def uhook_category_form form
            (form.hidden_field :content_id) + (hidden_field_tag(:from, params[:from]))
          end

          # Returns the locale information of this category
          def uhook_category_partial category
            locale = ::Locale.find_by_iso_code(category.locale)
            content_tag(:dt, ::Category.human_attribute_name("locale") + ':') +
            content_tag(:dd, (locale.native_name rescue t('ubiquo.category.any')))
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
            ::Category.locale(current_locale, :all)
          end

          # Initializes a new instance of category.
          def uhook_new_category
            ::Category.translate(params[:from], current_locale, :copy_all => true)
          end

          # Performs any required action on category when in show
          def uhook_show_category category
            unless category.in_locale?(current_locale)
              redirect_to(ubiquo_category_set_categories_url)
              false
            end
          end

          # Performs any required action on category when in edit
          def uhook_edit_category category
            unless category.in_locale?(current_locale)
              redirect_to(ubiquo_category_set_categories_url)
              false
            end
          end

          # Creates a new instance of category.
          def uhook_create_category
            category = ::Category.new(params[:category])
            category.locale = current_locale
            category
          end

          # Destroys a category instance. returns a success boolean
          def uhook_destroy_category(category)
            destroyed = false
            if params[:destroy_content]
              destroyed = category.destroy_content
            else
              destroyed = category.destroy
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
          def uhook_create_categories_table
            create_table :categories, :translatable => true do |t|
              yield t
            end
          end

          def uhook_create_category_relations_table
            create_table :category_relations do |t|
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
          end

          module ClassMethods
            # Adds the +categories+ to the +set+ and returns the categories that
            # will be effectively related to +object+
            def uhook_assign_to_set set, categories, object
              if object.class.is_translatable?
                locale = object.locale || Locale.current
              end
              categories_options = {}
              categories_options.merge!(:locale => locale)

              set.categories << [categories, categories_options]
              categories = Array(categories).reject(&:blank?)
              categories.map do |c|
                set.select_fittest(c, :locale => locale)
              end.uniq.compact
            end

            # Defines the relation as translation_shared if is a translatable class
            def uhook_categorized_with field, options
              association_name = field.to_s.pluralize.to_sym
              if self.is_translatable?
                share_translations_for association_name
              end
            end
          end

        end
      end

      module UbiquoHelpers
        module Helper
          # Returns a the applicable categories for +set+
          # +context+ can be a related object that restricts the possible categories
          def uhook_categories_for_set set, object = nil
            locale = if object && object.class.is_translatable?
              object.locale
            else
              current_locale
            end
            set.categories.locale(locale, :all)
          end
        end
      end

      def self.prepare_mocks
        add_mock_helper_stubs({
          :show_translations => '', :ubiquo_category_set_categories_url => '',
          :ubiquo_category_set_category_path => '', :current_locale => '',
          :content_tag => '', :hidden_field_tag => '', :locale => Category,
          :new_ubiquo_category_set_category_path => ''
        })
      end

    end
  end
end
