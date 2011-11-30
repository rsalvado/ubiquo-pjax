module UbiquoI18n
  module Adapters
    # Extends the create_table method to support the :translatable option
    module SchemaStatements
      extend Ubiquo::Tasks::Database

      # Perform the actual linking with create_table
      def self.included(klass)
        klass.send(:alias_method_chain, :create_table, :translatable)
        klass.send(:alias_method_chain, :change_table, :translatable)
      end

      # Parse the :translatable option as a create_table extension
      # This will currently add two fields:
      #   table.locale: string
      #   table.content_id sequence
      # with their respective indexes
      def create_table_with_translatable(*args, &block)
        SchemaStatements.apply_translatable_option!(:create_table, self, *args, &block)
      end

      # Parse the :translatable option as a change_table extension
      # This will currently add two fields:
      #   table.locale: string
      #   table.content_id sequence
      # with their respective indexes
      def change_table_with_translatable(*args, &block)
        SchemaStatements.apply_translatable_option!(:change_table, self, *args, &block)
      end

      # Performs the actual job of applying the :translatable option
      def self.apply_translatable_option!(method, adapter, table_name, options = {})
        translatable = options.delete(:translatable)
        locale       = options.delete(:locale)
        method_name  = "#{method}_without_translatable"

        # not all methods accept the options hash
        args = [table_name]
        args << options if adapter.method(method_name).arity != 1

        adapter.send(method_name, *args) do |table|
          if translatable
            table.string :locale, :nil => false
            table.sequence table_name, :content_id
          elsif translatable == false && method == :change_table
            table.remove :locale
            table.remove_sequence :test, :content_id
          end
          yield table
        end

        if translatable && method == :change_table
          fill_i18n_fields(table_name, adapter, locale)
        end

        # create or remove indexes for these new fields
        indexes = [:locale, :content_id]
        if translatable
          indexes.each do |index|
            unless adapter.indexes(table_name).map(&:columns).flatten.include? index.to_s
              adapter.add_index table_name, index
            end
          end
        elsif translatable == false # != nil
          indexes.each do |index|
            if adapter.indexes(table_name).map(&:columns).flatten.include? index.to_s
              adapter.remove_index table_name, index
            end
          end
        end
      end

      # In an existing table, fills the content_id and locale fields
      def self.fill_i18n_fields(table, adapter, locale)
        table_name = adapter.quote_table_name(table)

        # set content_id = id
        adapter.update("UPDATE #{table_name} SET #{adapter.quote_column_name('content_id')} = #{adapter.quote_column_name('id')}")
        fix_sequence_consistency(table_name)

        # fill the locale field for existing records
        locale ||= Locale.default
        adapter.update("UPDATE #{table_name} SET #{adapter.quote_column_name('locale')} = #{adapter.quote(locale)}")
      end

    end
  end
end
