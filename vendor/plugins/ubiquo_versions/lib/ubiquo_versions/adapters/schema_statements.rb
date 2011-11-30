module UbiquoVersions
  module Adapters
    # Extends the create_table method to support the :versionable option
    module SchemaStatements

      # Perform the actual linking with create_table
      def self.included(klass)
        klass.send(:alias_method_chain, :create_table, :versions)
        klass.send(:alias_method_chain, :change_table, :versions)
      end

      # Parse the :versionable option as a create_table extension
      # 
      # This will actually add four fields:
      #   table.version_number : sequence
      #   table.content_id : sequence
      #   table.is_current_version : boolean
      #   table.parent_version : integer
      # with their respective indexes (except for version_number)
      def create_table_with_versions(*args, &block)
        SchemaStatements.apply_versionable_option!(:create_table, self, *args, &block)
      end

      # Parse the :versionable option as a create_table extension
      #
      # This will actually add four fields:
      #   table.version_number : sequence
      #   table.content_id : sequence
      #   table.is_current_version : boolean
      #   table.parent_version : integer
      # with their respective indexes (except for version_number)
      def change_table_with_versions(*args, &block)
        SchemaStatements.apply_versionable_option!(:change_table, self, *args, &block)
      end

      # Performs the actual job of applying the :translatable option
      def self.apply_versionable_option!(method, adapter, table_name, options = {})
        versionable = options.delete(:versionable)
        method_name = "#{method}_without_versions"

        # not all methods accept the options hash
        args = [table_name]
        args << options if adapter.method(method_name).arity != 1
        
        adapter.send(method_name, *args) do |table|
          if versionable
            table.sequence table_name, :version_number
            table.sequence table_name, :content_id
            table.boolean :is_current_version, :null => false, :default => false
            table.integer :parent_version
          elsif versionable == false && method == :change_table
            table.remove :is_current_version, :parent_version
            table.remove_sequence :test, :version_number
            table.remove_sequence :test, :content_id
          end
          yield table
        end

        # create or remove indexes for these new fields
        indexes = [:is_current_version, :parent_version, :content_id]
        if versionable
          indexes.each do |index|
            unless adapter.indexes(table_name).map(&:columns).flatten.include? index.to_s
              adapter.add_index table_name, index
            end
          end
        elsif versionable == false
          indexes.each do |index|
            if adapter.indexes(table_name).map(&:columns).flatten.include? index.to_s
              adapter.remove_index table_name, index
            end
          end
        end

      end
    end
  end
end
