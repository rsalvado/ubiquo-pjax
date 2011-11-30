module Ubiquo
  module Adapters
    module Postgres
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        
        # Creates a sequence with name "name". Drops it before if it exists
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE SEQUENCE %s;" % name)
        end
        
        # Drops a sequence with name "name" if exists 
        def drop_sequence(name)
          if(list_sequences("").include?(name.to_s))
            self.execute("DROP SEQUENCE %s;" % name)
          end
        end
        
        # Returns an array containing a list of the existing sequences that start with the given string
        def list_sequences(starts_with)
          self.execute("SELECT c.relname AS sequencename FROM pg_class c WHERE (c.relkind = 'S' and c.relname ILIKE E'#{starts_with}%');").entries.map { |result| result['sequencename'] }
        end
        
        # Returns the next value for the sequence "name"
        def next_val_sequence(name)
          self.execute("SELECT nextval('%s');" % name).entries.first['nextval'].to_i
        end
        
        # Reset a sequence so that it will return the specified value as the next one
        # If next_value is not specified, the sequence will be reset to the "most appropiate value",
        # considering the values of existing records using this sequence
        def reset_sequence_value(name, next_value = nil)
          table, field = name.split('_$_')
          unless next_value
            next_value = self.execute('SELECT MAX(%s) as max FROM %s' % [field, table]).entries.first['max'].to_i + 1
          end
          self.execute("SELECT setval('%s', %s, false);" % [name, next_value])
        end
      end
    end
  end
end
