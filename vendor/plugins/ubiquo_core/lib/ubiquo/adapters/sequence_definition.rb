module Ubiquo
  module Adapters
    module SequenceDefinition
      
      # Creates an integer and an associated sequence field
      def sequence(table_name, field_name)
        integer field_name
        ActiveRecord::Base.connection.create_sequence("%s_$_%s" % [table_name, field_name])
      end

      # Undoes the field and sequence created by the +sequence+ method
      def remove_sequence(table_name, field_name)
        remove field_name
        ActiveRecord::Base.connection.drop_sequence("%s_$_%s" % [table_name, field_name])
      end
    end
  end
end
