module Ubiquo
  module Extensions
    module DistinctOption

      def self.extended klass
        klass.singleton_class.class_eval do |metaclass|
          metaclass::VALID_FIND_OPTIONS << :distinct
          alias_method_chain :construct_finder_sql,      :distinct
          alias_method_chain :construct_calculation_sql, :distinct
        end
      end

      # Applies the :distinct option when constructing sql queries
      def construct_finder_sql_with_distinct(options)
        scope = scope(:find)
        if options[:distinct] || (scope && scope[:distinct])
          options_with_distinct = options.merge(:select => select_distinct(options))
        end
        construct_finder_sql_without_distinct(options_with_distinct || options)
      end

      # Applies the :distinct option when constructing COUNT sql queries
      def construct_calculation_sql_with_distinct(operation, column_name, options)
        scope = scope(:find)
        if scope && scope[:distinct]
          column_name = [connection.quote_table_name(table_name), primary_key] * '.'
          options_with_distinct = options.merge(:distinct => true)
        end
        construct_calculation_sql_without_distinct(operation, column_name, options_with_distinct || options)
      end

      # Creates a valid SELECT DISTINCT clause,
      # that in Postgres takes into account the content in options[:order]
      def select_distinct(options)
        if connection.adapter_name == 'PostgreSQL'
          scope = scope(:find) rescue nil
          rails_select = options[:select] || (scope && scope[:select]) || default_select(true)

          # By default table.id is the distinct on clause.
          # The +order_fields+ (["table1.field1", "table2.field2"])
          # should be inside the distinct on clause, else postgres will fail.
          order_fields = get_order_fields(options)
          distinct_fields = ["#{table_name}.#{primary_key}", *order_fields].compact

          "DISTINCT ON (#{distinct_fields.join(',')}) #{rails_select}"
        else
          "DISTINCT (#{table_name}.#{primary_key})"
        end

      end

      # Given an +options+ hash and the possibly applied scopes,
      # returns the model fields that are being used to order.
      def get_order_fields(options)
        scope = scope(:find) rescue nil
        if order = (options[:order] || (scope && scope[:order]))
          # general case: order is "table1.field1 asc, table2.field2 DESC"
          orders = order.split(',').map{|ord| ord.split(' ')}

          # now +orders+ is [["table1.field1", "asc"], ["table2.field2", "DESC"]]
          order_fields = orders.map{|order_part| order_part.first}
        end
      end

    end
  end
end
