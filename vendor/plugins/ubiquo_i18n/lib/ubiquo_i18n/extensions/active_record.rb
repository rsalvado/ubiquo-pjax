module UbiquoI18n
  module Extensions
    module ActiveRecord

      def self.append_features(base)
        super
        base.extend(ClassMethods)
        base.send :include, InstanceMethods
      end

      module ClassMethods

        # Class method for ActiveRecord that states which attributes are translatable and therefore when updated will be only updated for the current locale.
        #
        # EXAMPLE:
        #
        #   translatable :title, :description
        #
        # possible options:
        #   :timestamps => set to false to avoid translatable (i.e. independent per translation) timestamps

        def translatable(*attrs)
         
          # inherit translatable attributes
          @translatable_attributes = self.translatable_attributes || []

          @really_translatable_class = self
          @translatable = true

          # delete the specific validation to avoid problem with connector reloading in tests
          self.clear_locale_uniqueness_per_entity_validation

          # assure no duplicated objects for the same locale
          validates_uniqueness_of(:locale,
            :identifier => uniqueness_per_entity_validation_identifier,
            :scope => :content_id,
            :case_sensitive => false,
            :message => Proc.new { |*attrs|
              # used in console and test when we do manually a
              #    translation = object.translate('hola')
              locale = attrs.first
              # used as in controller when we do a normal create with a content_id
              #
              #    translation = Model.create(:field => 'foo', :content_id => 1)
              locale = attrs.last[:value] rescue false
              humanized_locale = Locale.find_by_iso_code(locale)
              humanized_locale = humanized_locale.english_name if humanized_locale
              I18n.t('ubiquo.i18n.locale_uniqueness_per_entity',
                      :model => self.human_name,
                      :object_locale => humanized_locale)
            })
          # extract and parse options
          options = attrs.extract_options!
          # add attrs from this class
          @translatable_attributes += attrs

          # timestamps are independent per translation unless set
          @translatable_attributes += [:created_at, :updated_at] unless options[:timestamps] == false
          # when using optimistic locking, lock_version has to be independent per translation
          @translatable_attributes += [:lock_version]

          # try to generate the attribute setter
          self.new.send(:locale=, :generate) rescue nil
          if instance_methods.include?('locale=') && !instance_methods.include?('locale_with_duality=')
            # give the proper behaviour to the locale setter
            define_method('locale_with_duality=') do |locale|
              locale = case locale
              when String
                locale
              else
                locale.iso_code if locale.respond_to?(:iso_code)
              end
              send(:locale_without_duality=, locale)
            end

            alias_method_chain :locale=, :duality

          end

          unless instance_methods.include?("in_locale")
            define_method('in_locale') do |*locales|
              self.class.locale(*locales).first(:conditions => {:content_id => self.content_id})
            end
          end

          # Checks if the instance has a locale in the given a locales list
          # The last parameter can be an options hash
          #   :skip_any => if true, ignore items with the :any locale.
          #                else, these items always return true
          define_method('in_locale?') do |*asked_locales|
            options = asked_locales.extract_options!
            options.reverse_merge!({
              :skip_any => false
            })
            asked_locales.map(&:to_s).include?(self.locale) ||
              (!options[:skip_any] && self.locale == 'any')
          end

          # usage:
          # find all content in any locale: Model.locale(:all)
          # find spanish content: Model.locale('es')
          # find spanish or english content. If spanish and english exists, gets the spanish version. Model.locale('es', 'en')
          # find all content in spanish or any other locale if spanish dosn't exist: Model.locale('es', :all)
          # find all content in any locale: Model.locale(:all)
          #
          named_scope :locale, lambda{|*locales|
            if locales.delete(:ALL)
              locales << :all
              ActiveSupport::Deprecation.warn('Use :all instead of :ALL in locale()', caller(5))
            end

            {:locale_scoped => true, :locale_list => locales}
          }

          # usage:
          # find all items of one content: Model.content(1).first
          # find all items of some contents: Model.content(1,2,3)
          named_scope :content, lambda{|*content_ids|
            {:conditions => {:content_id => content_ids}}
          }

          # usage:
          # find all translations of a given content: Model.translations(content)
          # will use the defined scopes to discriminate what are translations
          # remember it won't return 'content' itself
          named_scope :translations, lambda{|content|
            scoped_conditions = []
            @translatable_scopes.each do |scope|
                scoped_conditions << (String === scope ? scope : scope.call(content))
            end
             translation_condition = "#{self.table_name}.content_id = ? AND #{self.table_name}.locale != ?"
            unless scoped_conditions.blank?
              translation_condition += ' AND ' + scoped_conditions.join(' AND ')
            end
            {:conditions => [translation_condition, content.content_id, content.locale]}
          }

          # Apply these named scopes to any possible already loaded subclass
          subclasses.each do |klass|
            klass.scopes.merge! scopes.slice(:locale, :translations, :content)
          end

          # Instance method to find translations
          define_method('translations') do
            self.class.translations(self)
          end

          # Returns an array containing self and its translations
          define_method('with_translations') do
            [self] + translations
          end

          # Creates a new instance of the translatable class, using the common
          # values from an instance sharing the same content_id
          # Returns a new independent instance if content_id is nil or not found
          # Options can be one of these:
          #   :copy_all => if true, will copy all the attributes from the original, even the translatable ones
          def translate(content_id, locale, options = {})
            original = find_by_content_id(content_id)
            new_translation = original ? original.translate(locale, options) : new
            new_translation.locale = locale
            new_translation
          end

          # Creates (saving) a new translation of self, with the common values filled in
          define_method('translate') do |*attrs|
            locale = attrs.first
            options = attrs.extract_options!
            options[:copy_all] = options[:copy_all].nil? ? true : options[:copy_all]

            new_translation = self.class.new
            new_translation.locale = locale

            # copy of attributes
            clonable_attributes = options[:copy_all] ? :attributes_except_unique_for_translation : :untranslatable_attributes
            self.send(clonable_attributes).each_pair do |attr, value|
              new_translation.send("#{attr}=", value)
            end

            # copy of relations
            new_translation.copy_translatable_shared_relations_from self
            new_translation
          end


          # Looks for defined shared relations and performs a chain-update on them
          define_method('copy_translatable_shared_relations_from') do |model|
            # here a clean environment is needed, but save Locale.current
            without_current_locale do
              self.class.is_translating_relations = true
              begin
                must_save = false
                # act on reflections where translatable == false
                self.class.translation_shared_relations.each do |association_id, reflection_values|
                  association_values = model.send("#{association_id}_without_shared_translations")
                  record = [association_values].flatten.first

                  if record && record.class.is_translatable?

                    all_relationship_contents = []
                    [association_values].flatten.each do |related_element|
                      existing_translation = related_element.translations.locale(locale).first
                      if existing_translation
                        all_relationship_contents << existing_translation
                      else
                        all_relationship_contents << related_element
                      end
                    end

                  elsif record

                    if reflection_values.macro == :belongs_to
                      # we simply copy the attribute value
                      all_relationship_contents = [association_values]
                    else
                      raise "This behaviour is not supported by ubiquo_i18n. Either use a has_many :through to a translatable model or mark the #{record.class} model as translatable"
                    end

                  elsif reflection_values.macro == :belongs_to
                     # no record means that we are removing an association, so the new content is nil
                    all_relationship_contents = [nil]
                  else
                    next
                  end

                  all_relationship_contents = all_relationship_contents.first unless association_values.is_a?(Array)
                  self.send(association_id.to_s + '=', all_relationship_contents)
                  if reflection_values.macro == :belongs_to && !new_record?
                    # belongs_to is not autosaved by rails when the association is not new
                    must_save = true
                  end
                end
                save if must_save
              ensure
                self.class.is_translating_relations = false
              end
            end
          end

          # Do any necessary treatment when we are about to propagate changes from an instance to its translations
          define_method 'prepare_for_shared_translations' do
            # Rails doesn't reload the belongs_to associations when the _id field is changed,
            # which causes cached data to persist when it's already obsolete
            self.class.translation_shared_relations.select do |name, reflection|
              if reflection.macro == :belongs_to
                if has_updated_existing_primary_key(reflection)
                  association = self.send("#{name}_without_shared_translations")
                  association.reload if association
                end
              end
            end
          end

          # Returns true if the primary_key for +reflection+ has been changed, and it was not nil before
          define_method 'has_updated_existing_primary_key' do |reflection|
            send("#{reflection.primary_key_name}_changed?") && send("#{reflection.primary_key_name}_was")
          end

          define_method 'destroy_content' do
            self.translations.each(&:destroy)
            self.destroy
          end

        end

        def share_translations_for(*associations)
          associations.each do |association_id|

            reflection = reflections[association_id]
            reflection.options[:translation_shared] = true

            unless is_translation_shared_initialized? association_id
              define_method "#{association_id}_with_shared_translations" do

                association = self.send("#{association_id}_without_shared_translations")

                # do nothing if we don't have a current locale and we aren't in a translatable instance
                return association if !Locale.current && !self.class.is_translatable?

                # preferred locale for the associated objects
                locale = Locale.current || self.locale

                is_collection = association.respond_to? :count
                # the target needs to be loaded
                association.inspect

                if is_collection && reflection.klass.is_translatable?
                  # build the complete proxy_target
                  target = association.proxy_target
                  contents = []
                  # if this instance is not from a translatable class, it won't have the with_translations method
                  origin = self.class.is_translatable? ? self.with_translations : self
                  Array(origin).each do |translation|
                    elements = translation.send("#{association_id}_without_shared_translations")
                    elements.each do |element|
                      contents << element unless element.content_id && contents.map(&:content_id).include?(element.content_id)
                    end
                  end
                  target.clear
                  target.concat(contents)

                  # now "localize" the contents
                  translations_to_do = {}
                  target.each do |element|
                    if !element.in_locale?(locale) && (translation = element.in_locale(locale))
                      translations_to_do[element] = translation
                    end
                  end
                  translations_to_do.each_pair do |foreign, translation|
                    target.delete foreign
                    target << translation
                  end

                  association.loaded

                # it's a proxy and sometimes does not return the same as .nil?
                elsif !is_collection && !association.is_a?(NilClass)
                  # one-sized association, not a collection
                  if association.class.is_translatable? && !association.in_locale?(locale)
                    association = association.in_locale(locale) || association
                  end

                elsif association.is_a? NilClass
                  # in a has_one, with a nil association we have to look at translations
                  translations.map do |translation|
                    element = translation.send("#{association_id}_without_shared_translations")
                    if element
                      if element.class.is_translatable? && !element.in_locale?(locale)
                        element = element.in_locale(locale)
                      end
                      association = element
                      break
                    end
                  end

                end

                association
              end

              alias_method_chain association_id, :shared_translations

              # Syncs the deletion of association elements across translations
              add_association_callbacks(
                association_id,
                :after_remove => Proc.new{ |record, removed|
                  record.class.translating_relations do
                    record.translations.each do |translation|
                      translation.send(association_id).delete removed.with_translations
                    end
                  end
                }
              ) if is_translatable?

              # Marker to avoid recursive redefinition
              initialize_translation_shared association_id

            end

          end

        end

        # Given a reflection, will process the :translation_shared option
        def process_translation_shared reflection
          reset_translation_shared reflection.name
          if reflection.options[:translation_shared]
            share_translations_for reflection.name
          end
        end

        # Returns the reflections which are translation_shared
        def translation_shared_relations
          self.reflections.select do |name, reflection|
            reflection.options[:translation_shared]
          end
        end

        # Returns the value for the var_name instance variable, or if this is nil,
        # follow the superclass chain to ask the value
        def instance_variable_inherited_get(var_name, method_name = nil)
          method_name ||= var_name
          value = instance_variable_get("@#{var_name}")
          if value.nil? && !@really_translatable_class
            self.superclass.respond_to?(method_name) && self.superclass.send(method_name)
          else
            value
          end
        end

        # Sets the value for the var_name instance variable, or if this is nil,
        # follow the superclass chain to set the value
        def instance_variable_inherited_set(value, var_name, method_name = nil)
          method_name ||= var_name
          if !@really_translatable_class
            self.superclass.respond_to?(method_name) && self.superclass.send(method_name, value)
          else
            instance_variable_set("@#{var_name}", value)
          end
        end

        # Returns true if the class is marked as translatable
        def is_translatable?
          instance_variable_inherited_get("translatable", "is_translatable?")
        end

        # Returns a list of translatable attributes for this class
        def translatable_attributes
          instance_variable_inherited_get("translatable_attributes")
        end

        # Returns the class that really calls the translatable method
        def really_translatable_class
          instance_variable_inherited_get("really_translatable_class")
        end

        # Returns true if this class is currently translating relations
        def is_translating_relations
          instance_variable_inherited_get("is_translating_relations")
        end

        # Sets the value of the is_translating_relations flag
        def is_translating_relations=(value)
          instance_variable_inherited_set(value, "is_translating_relations", "is_translating_relations=")
        end

        # Wrapper for translating relations preventing cyclical chain updates
        def translating_relations
          unless is_translating_relations
            self.is_translating_relations = true
            begin
              yield
            ensure
              self.is_translating_relations = false
            end
          end
        end

        # Returns true if the translatable propagation has been set to stop
        def stop_translatable_propagation
          instance_variable_inherited_get("stop_translatable_propagation")
        end

        # Setter for the stop_translatable_propagation_flag
        def stop_translatable_propagation=(value)
          instance_variable_inherited_set(value, "stop_translatable_propagation", "stop_translatable_propagation=")
        end

        # Returns true if the translation-shared association has been initialized
        def is_translation_shared_initialized? association_id = nil
          associations = initialized_translation_shared_list
          associations.is_a?(Array) && associations.include?(association_id)
        end

        # Returns the list of associations initialized
        def initialized_translation_shared_list
          instance_variable_inherited_get("initialized_translation_shared_list")
        end

        # Marks the association as initialized
        def initialize_translation_shared association_id
          new_association = Array(association_id)
          associations = instance_variable_inherited_get("initialized_translation_shared_list") || []
          associations +=  new_association
          instance_variable_inherited_set(associations, "initialized_translation_shared_list", "initialize_translation_shared")
        end

        # Unmarks an association as translation-shared initialized
        def reset_translation_shared association_id
          reset_association = Array(association_id)
          associations = instance_variable_inherited_get("initialized_translation_shared_list") || []
          associations -=  reset_association
          instance_variable_inherited_set(associations, "initialized_translation_shared_list", "reset_translation_shared")
        end

        # Applies the locale filter if needed, then performs the normal find method
        def find_with_locale_filter(*args)
          if self.is_translatable?
            options = args.extract_options!
            apply_locale_filter!(options)
            find_without_locale_filter(args.first, options)
          else
            find_without_locale_filter(*args)
          end
        end

        # Applies the locale filter if needed, then performs the normal count method
        def count_with_locale_filter(*args)
          if self.is_translatable?
            options = args.extract_options!
            apply_locale_filter!(options)
            count_without_locale_filter(args.first || :all, options)
          else
            count_without_locale_filter(*args)
          end
        end


        # Attributes that are always 'translated' (not copied between languages)
        (@global_translatable_attributes ||= []) << :locale << :content_id

        # Used by third parties to add fields that should always
        # be independent between different languages
        def add_translatable_attributes(*args)
          @global_translatable_attributes += args
        end

        # Define scopes to limit the automatic update of common fields to instances
        # that have the same value for each scope (as a field name)
        @translatable_scopes ||= []

        # Used by third parties to add scopes for translations updates of common fields
        # It accepts two formats for condition:
        # - A String with a sql where condition (e.g. is_active = 1)
        # - A Proc that will be called with the current element argument and
        #   that should return a string (e.g. lambda{|el| "table.field = #{el.field + 1}"})
        def add_translatable_scope(condition)
          @translatable_scopes << condition
        end

        @@translatable_inheritable_instance_variables = %w{global_translatable_attributes translatable_scopes}

        ASSOCIATION_TYPES = %w{ has_one belongs_to has_many has_and_belongs_to_many }

        def self.extended(klass)
          # Ensure that the needed variables are inherited
          @@translatable_inheritable_instance_variables.each do |inheritable|
            unless eval("@#{inheritable}").nil?
              klass.instance_variable_set("@#{inheritable}", eval("@#{inheritable}").dup)
            end
          end

          # Aliases the find and count methods to apply the locale filter
          klass.class_eval do
            class << self
              alias_method_chain :find, :locale_filter
              alias_method_chain :count, :locale_filter
              VALID_FIND_OPTIONS << :locale_scoped << :locale_list
            end
          end

          # Accept the :translation_shared option when defining associations
          ASSOCIATION_TYPES.each do |type|
            klass.send("valid_keys_for_#{type}_association") << :translation_shared
          end
        end

        def inherited(klass)
          super
          @@translatable_inheritable_instance_variables.each do |inheritable|
            unless eval("@#{inheritable}").nil?
              klass.instance_variable_set("@#{inheritable}", eval("@#{inheritable}").dup)
            end
          end
        end

        def clear_validation identifier
          self.validate.delete_if do |v|
            v.identifier == identifier
          end if self.validate.respond_to?(:delete_if)
        end

        def uniqueness_per_entity_validation_identifier
          :locale_uniqueness_per_entity
        end

        def clear_locale_uniqueness_per_entity_validation
          clear_validation uniqueness_per_entity_validation_identifier
        end

        private

        # This method is the one that actually applies the locale filter
        # This means that if you use .locale(..), you'll end up here,
        # when the results are actually delivered (not in call time)
        def apply_locale_filter!(options)
          apply_locale_filter = really_translatable_class.instance_variable_get(:@locale_scoped)
          locales = really_translatable_class.instance_variable_get(:@current_locale_list)
          # set this find as dispatched
          really_translatable_class.instance_variable_set(:@locale_scoped, false)
          really_translatable_class.instance_variable_set(:@current_locale_list, [])
          if apply_locale_filter
            # build locale restrictions
            locales = merge_locale_list locales.reverse!
            all_locales = locales.delete(:all)

            # add untranslatable instances if necessary
            locales << :any unless all_locales || locales.size == 0

            if all_locales
              locale_conditions = ""
            else
              locale_conditions = ["#{self.table_name}.locale in (?)", locales.map(&:to_s)]
              # act like a normal condition when we are just filtering a locale
              if locales.size == 2 && locales.include?(:any)
                options[:conditions] = merge_conditions(options[:conditions], locale_conditions)
                return
              end
            end
            # locale preference order
            tbl = self.table_name
            locales_string = locales.size > 0 ? (["#{tbl}.locale != ?"]*(locales.size)).join(", ") : nil
            locale_order = ["#{tbl}.content_id", locales_string].compact.join(", ")

            adapters_with_custom_sql = %w{PostgreSQL MySQL}
            current_adapter = ::ActiveRecord::Base.connection.adapter_name
            if adapters_with_custom_sql.include?(current_adapter)

              # Certain adapters support custom features that allow the locale
              # filter to do its job in a single sql. We use them for efficiency
              # In these cases, the subquery that will be build must respect
              # includes, joins and conditions from the original query

              current_includes = merge_includes(scope(:find, :include), options[:include])
              dependency_class = ::ActiveRecord::Associations::ClassMethods::JoinDependency
              join_dependency = dependency_class.new(self, current_includes, options[:joins])
              joins_sql = join_dependency.join_associations.collect{|join| join.association_join }.join
              # at this point, joins_sql in fact only includes the joins coming from options[:include]
              add_joins!(joins_sql, options[:joins])
              add_conditions!(conditions_sql = '', merge_conditions(locale_conditions, options[:conditions]), scope(:find))

              # now construct the subquery
              locale_filter = case current_adapter
              when "PostgreSQL"
                # use a subquery with DISTINCT ON, more efficient, but currently
                # only supported by Postgres

                ["#{tbl}.id in (" +
                    "SELECT distinct on (#{tbl}.content_id) #{tbl}.id " +
                    "FROM #{tbl} " + joins_sql.to_s + conditions_sql.to_s +
                    "ORDER BY #{locale_order})", *locales.map(&:to_s)
                ]

              when "MySQL"
                # it's a "within-group aggregates" problem. We need to order before grouping.
                # This subquery is O(N * log N), while a correlated subquery would be O(N^2)

                ["#{tbl}.id in (" +
                    "SELECT id FROM ( SELECT #{tbl}.id, #{tbl}.content_id " +
                    "FROM #{tbl} " + joins_sql.to_s + conditions_sql.to_s +
                    "ORDER BY #{locale_order}) AS lpref " +
                    "GROUP BY content_id)", *locales.map(&:to_s)
                ]
              end

              # finally, merge the created subquery into the current conditions
              options[:conditions] = merge_conditions(options[:conditions], locale_filter)

            else
              # For the other adapters, the strategy is to do two subqueries.
              # This can be problematic for generic queries since we have to
              # suppress the paginator scope to guarantee the correctness (#254)

              # find the final IDs
              ids = nil

              # redefine after_find callback method avoiding its call with next find
              self.class_eval do
                def after_find_with_neutralize; end
                def after_initialize_with_neutralize; end
                alias_method_chain :after_find, :neutralize if self.instance_methods.include?("after_find")
                alias_method_chain :after_initialize, :neutralize if self.instance_methods.include?("after_initialize")
              end

              begin
                # record possible scoped conditions
                previous_conditions = scope(:find, :conditions)
                # removes paginator scope.
                with_exclusive_scope(:find => {:limit => nil, :offset => nil, :joins => scope(:find, :joins), :include => scope(:find, :include)}) do
                  conditions = merge_conditions(locale_conditions, options[:conditions])
                  conditions = merge_conditions(conditions, previous_conditions)

                  ids = find(:all, {
                      :select => "#{tbl}.id, #{tbl}.content_id ",
                      :order => sanitize_sql_for_conditions(["#{locale_order}", *locales.map(&:to_s)]),
                      :conditions => conditions,
                      :include => options[:include],
                      :joins => options[:joins]
                  })
                end
              ensure
                #restore after_find callback method
                self.class_eval do
                  alias_method :after_find, :after_find_without_neutralize if self.instance_methods.include?("after_find")
                  alias_method :after_initialize, :after_initialize_without_neutralize if self.instance_methods.include?("after_initialize")
                end
              end

              #get only one ID per content_id
              content_ids = {}
              ids = ids.select{ |id| content_ids[id.content_id].nil? ? content_ids[id.content_id] = id : false }.map{|id| id.id.to_i}

              options[:conditions] = merge_conditions(options[:conditions], {:id => ids})
            end
          end
        end

        def merge_locale_list locales
          merge_locale_list_rec locales.first, locales[1,locales.size]
        end

        def merge_locale_list_rec previous, rest
          new = rest.first
          return previous.clone unless new
          merged = if previous.empty? || previous.include?(:all)
            new
          else
            previous & new
          end
          merged = previous if merged.empty? && new.include?(:all)
          merge_locale_list_rec merged, rest[1,rest.size]
        end

      end

      module InstanceMethods

        def self.included(klass)
          klass.send :before_validation, :initialize_i18n_fields
          klass.alias_method_chain :update, :translatable
          klass.alias_method_chain :create, :translatable
          klass.alias_method_chain :create, :i18n_fields
        end

        # proxy to add a new content_id if empty on creation
        def create_with_i18n_fields
          initialize_i18n_fields
          create_without_i18n_fields
        end

        def initialize_i18n_fields
          if self.class.is_translatable?
            # we do this even if there is not currently any tr. attribute,
            # as long as is a translatable model
            unless self.content_id
              self.content_id = self.class.connection.next_val_sequence("#{self.class.table_name}_$_content_id")
            end
            unless self.locale
              self.locale = Locale.current
            end
          end
        end

        # Whenever we update existing content or create a translation, the expected behaviour is the following
        # - The translatable fields will be updated just for the current instance
        # - Fields not defined as translatable will need to be updated for every instance that shares the same content_id
        def create_with_translatable
          saved = create_without_translatable
          update_translations if saved
          saved
        end

        def update_with_translatable
          if self.class.is_translatable? && !@stop_translatable_propagation
            if Locale.current && !in_locale?(Locale.current)
              translation = in_locale(Locale.current) || translate(Locale.current)
              self.send(:attributes_except_unique_for_translation).each_pair do |attr, value|
                translation.send("#{attr}=", value)
              end
              translation.save
            else
              saved = update_without_translatable
              update_translations if saved
              saved
            end
          else
            update_without_translatable
          end
        end

        def update_translations
          if self.class.is_translatable? && !@stop_translatable_propagation
            # prepare "self" to be the relations model for its translations
            self.prepare_for_shared_translations
            # Update the translations
            self.translations.each do |translation|
              translation.instance_variable_set('@stop_translatable_propagation', true)
              begin
                translation.update_attributes untranslatable_attributes
                translation.copy_translatable_shared_relations_from self
              ensure
                translation.instance_variable_set('@stop_translatable_propagation', false)
              end
            end
          end
        end

        def untranslatable_attributes_names
          translatable_attributes = (self.class.translatable_attributes || []) +
            (self.class.instance_variable_get('@global_translatable_attributes') || []) +
            (self.class.reflections.select do |name, ref|
                ref.macro != :belongs_to ||
                !ref.options[:translation_shared] ||
                ((model = [send(name)].first) && model.class.is_translatable?)
            end.map{|name, ref| ref.primary_key_name})
          attribute_names - translatable_attributes.map{|attr| attr.to_s}
        end

        def untranslatable_attributes
          attrs = {}
          (untranslatable_attributes_names + ['content_id'] - ['id']).each do |name|
            attrs[name] = clone_attribute_value(:read_attribute, name)
          end
          attrs
        end


        def attributes_except_unique_for_translation
          attributes.reject{|attr, value| [:id, :locale].include?(attr.to_sym)}
        end

        # Used to execute a block disabling automatic translation update for this instance
        def without_updating_translations
          previous_value = @stop_translatable_propagation
          @stop_translatable_propagation = true
          begin
            yield
          ensure
            @stop_translatable_propagation = previous_value
          end
        end

        # Execute a block without being affected by any possible current locale
        def without_current_locale
          begin
            @current_locale, Locale.current = Locale.current, nil if Locale.current
            yield
          ensure
            Locale.current = @current_locale
          end
        end

      end

    end
  end
end
