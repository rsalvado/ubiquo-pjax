module Ubiquo
  module Adapters
    module Mysql
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        
        # Creates a sequence with name "name". Drops it before if it exists
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE TABLE %s_sequence (id INTEGER PRIMARY KEY auto_increment)" % name)
        end
        
        # Drops a sequence with name "name" if exists 
        def drop_sequence(name)
          self.execute("DROP TABLE IF EXISTS %s_sequence" % name)
        end
        
        # Returns an array containing a list of the existing sequences that start with the given string
        def list_sequences(starts_with)
          self.select_rows("SHOW TABLES LIKE '#{starts_with}%_sequence'").map { |result| result.first.gsub('_sequence', '') }
        end
        
        # Returns the next value for the sequence "name"
        def next_val_sequence(name)
          if self.class.equal? ActiveRecord::ConnectionAdapters::MysqlAdapter
            self.insert_sql("INSERT INTO %s_sequence VALUES(NULL)" % name)
          else
            # the default insert_sql is nonsense, but jdbc_mysql doesn't override it
            self.execute("INSERT INTO %s_sequence VALUES(NULL)" % name)
          end
        end
        
        # Reset a sequence so that it will return the specified value as the next one
        # If next_value is not specified, the sequence will be reset to the "most appropiate value",
        # considering the values of existing records using this sequence
        def reset_sequence_value(name, next_value = nil)
          create_sequence(name)
          unless next_value
            table, field = name.split('_$_')
            next_value = self.select_rows('SELECT MAX(%s) as max FROM %s' % [field, table]).first.first.to_i + 1
          end
          self.execute("ALTER TABLE %s_sequence AUTO_INCREMENT = %s" % [name, next_value || 1])
        end
      end
    end
  end
end
