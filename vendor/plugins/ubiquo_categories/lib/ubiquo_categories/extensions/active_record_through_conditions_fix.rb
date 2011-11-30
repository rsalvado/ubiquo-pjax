module ActiveRecord
  module Associations
    module ClassMethods
      class JoinDependency
        class JoinAssociation
      def association_join
        connection = reflection.active_record.connection
        join = case reflection.macro
          when :has_and_belongs_to_many
            " #{join_type} %s ON %s.%s = %s.%s " % [
               table_alias_for(options[:join_table], aliased_join_table_name),
               connection.quote_table_name(aliased_join_table_name),
               options[:foreign_key] || reflection.active_record.to_s.foreign_key,
               connection.quote_table_name(parent.aliased_table_name),
               reflection.active_record.primary_key] +
            " #{join_type} %s ON %s.%s = %s.%s " % [
               table_name_and_alias,
               connection.quote_table_name(aliased_table_name),
               klass.primary_key,
               connection.quote_table_name(aliased_join_table_name),
               options[:association_foreign_key] || klass.to_s.foreign_key
               ]
          when :has_many, :has_one
            case
              when reflection.options[:through]
                through_conditions = through_reflection.options[:conditions] ? " AND #{interpolate_sql(sanitize_sql(through_reflection.options[:conditions]))}" : ''

                jt_foreign_key = jt_as_extra = jt_source_extra = jt_sti_extra = nil
                first_key = second_key = as_extra = nil

                if through_reflection.options[:as] # has_many :through against a polymorphic join
                  jt_foreign_key = through_reflection.options[:as].to_s + '_id'
                  jt_as_extra = " AND %s.%s = %s" % [
                    connection.quote_table_name(aliased_join_table_name),
                    connection.quote_column_name(through_reflection.options[:as].to_s + '_type'),
                    klass.quote_value(parent.active_record.base_class.name)
                  ]
                else
                  jt_foreign_key = through_reflection.primary_key_name
                end

                case source_reflection.macro
                when :has_many
                  if source_reflection.options[:as]
                    first_key   = "#{source_reflection.options[:as]}_id"
                    second_key  = options[:foreign_key] || primary_key
                    as_extra    = " AND %s.%s = %s" % [
                      connection.quote_table_name(aliased_table_name),
                      connection.quote_column_name("#{source_reflection.options[:as]}_type"),
                      klass.quote_value(source_reflection.active_record.base_class.name)
                    ]
                  else
                    first_key   = through_reflection.klass.base_class.to_s.foreign_key
                    second_key  = options[:foreign_key] || primary_key
                  end

                  unless through_reflection.klass.descends_from_active_record?
                    jt_sti_extra = " AND %s.%s = %s" % [
                      connection.quote_table_name(aliased_join_table_name),
                      connection.quote_column_name(through_reflection.active_record.inheritance_column),
                      through_reflection.klass.quote_value(through_reflection.klass.sti_name)]
                  end
                when :belongs_to
                  first_key = primary_key
                  if reflection.options[:source_type]
                    second_key = source_reflection.association_foreign_key
                    jt_source_extra = " AND %s.%s = %s" % [
                      connection.quote_table_name(aliased_join_table_name),
                      connection.quote_column_name(reflection.source_reflection.options[:foreign_type]),
                      klass.quote_value(reflection.options[:source_type])
                    ]
                  else
                    second_key = source_reflection.primary_key_name
                  end
                end

                " #{join_type} %s ON (%s.%s = %s.%s%s%s%s%s) " % [
                  table_alias_for(through_reflection.klass.table_name, aliased_join_table_name),
                  connection.quote_table_name(parent.aliased_table_name),
                  connection.quote_column_name(parent.primary_key),
                  connection.quote_table_name(aliased_join_table_name),
                  connection.quote_column_name(jt_foreign_key),
                  jt_as_extra, jt_source_extra, jt_sti_extra, through_conditions
                ] +
                " #{join_type} %s ON (%s.%s = %s.%s%s) " % [
                  table_name_and_alias,
                  connection.quote_table_name(aliased_table_name),
                  connection.quote_column_name(first_key),
                  connection.quote_table_name(aliased_join_table_name),
                  connection.quote_column_name(second_key),
                  as_extra
                ]

              when reflection.options[:as] && [:has_many, :has_one].include?(reflection.macro)
                " #{join_type} %s ON %s.%s = %s.%s AND %s.%s = %s" % [
                  table_name_and_alias,
                  connection.quote_table_name(aliased_table_name),
                  "#{reflection.options[:as]}_id",
                  connection.quote_table_name(parent.aliased_table_name),
                  parent.primary_key,
                  connection.quote_table_name(aliased_table_name),
                  "#{reflection.options[:as]}_type",
                  klass.quote_value(parent.active_record.base_class.name)
                ]
              else
                foreign_key = options[:foreign_key] || reflection.active_record.name.foreign_key
                " #{join_type} %s ON %s.%s = %s.%s " % [
                  table_name_and_alias,
                  aliased_table_name,
                  foreign_key,
                  parent.aliased_table_name,
                  reflection.options[:primary_key] || parent.primary_key
                ]
            end
          when :belongs_to
            " #{join_type} %s ON %s.%s = %s.%s " % [
               table_name_and_alias,
               connection.quote_table_name(aliased_table_name),
               reflection.options[:primary_key] || reflection.klass.primary_key,
               connection.quote_table_name(parent.aliased_table_name),
               options[:foreign_key] || reflection.primary_key_name
              ]
          else
            ""
        end || ''
        join << %(AND %s) % [
          klass.send(:type_condition, aliased_table_name)] unless klass.descends_from_active_record?

        [through_reflection, reflection].each do |ref|
          join << "AND #{interpolate_sql(sanitize_sql(ref.options[:conditions], aliased_table_name))} " if ref && ref.options[:conditions]
        end

        join
      end
    end
  end
end
end
end
