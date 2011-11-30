module Ubiquo
  module Adapters
    module Sqlite
      def self.included(klass)
        klass.send :include, InstanceMethods

        if RUBY_PLATFORM =~ /java/
          # support for custom function creation for the jdbc adapter
          ::ActiveRecord::ConnectionAdapters::Sqlite3JdbcConnection.send(:include, Sqlite3JdbcFunctions)
        end

        klass.alias_method_chain :initialize, :regexp

        if ActiveRecord::Base.connection
          # initialize regexp for the already established connection
          ActiveRecord::Base.connection.create_regexp_method
        end
      end

      module InstanceMethods

        def initialize_with_regexp connection, logger, config
          initialize_without_regexp connection, logger, config
          create_regexp_method
        end

        # creates a regexp method to allow use the REGEXP operator
        def create_regexp_method
          @connection.create_function('regexp', 2) do |func, pattern, expression|
            regexp = Regexp.new(pattern.to_s, Regexp::IGNORECASE)
            func.result = expression.to_s.match(regexp) ? 1 : 0
          end
        end

        # Creates a sequence with name "name". Drops it before if it exists
        def create_sequence(name)
          drop_sequence(name)
          self.execute("CREATE TABLE %s_sequence (id INTEGER PRIMARY KEY AUTOINCREMENT)" % name)
        end

        # Drops a sequence with name "name" if exists
        def drop_sequence(name)
          self.execute("DROP TABLE IF EXISTS %s_sequence" % name)
        end

        # Returns an array containing a list of the existing sequences that start with the given string
        def list_sequences(starts_with)
          self.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND NOT name = 'sqlite_sequence' AND name LIKE '#{starts_with}%'").map { |result| result['name'].gsub('_sequence', '') }
        end

        # Returns the next value for the sequence "name"
        def next_val_sequence(name)
          val = self.insert_sql("INSERT INTO %s_sequence VALUES(NULL)" % name)
          # In jdbcsqlite, insert_sql is not implemented
          val ||= last_insert_id("#{name}_sequence", nil) rescue nil
        end

        # Reset a sequence so that it will return the specified value as the next one
        # If next_value is not specified, the sequence will be reset to the "most appropiate value",
        # considering the values of existing records using this sequence
        def reset_sequence_value(name, next_value = nil)
          create_sequence(name)
          unless next_value
            table, field = name.split('_$_')
            next_value = self.execute('SELECT MAX(%s) as max FROM %s' % [field, table]).first['max'].to_i + 1
          end
          self.execute("INSERT INTO %s_sequence VALUES(%s)" % [name, (next_value || 1) - 1])
        end
      end

      module Sqlite3JdbcFunctions
        # Creates a function with the same signature as SQLite::Database
        def create_function(name, arity, text_rep='default', &block)
          generic_function = Class.new(org.sqlite.Function)
          generic_function.class_eval do

            # All org.sqlite.Function subclasses must implement xFunc(),
            # which is called when SQLite runs the custom function
            define_method 'xFunc' do
              # receiver is the first expected argument for the block
              # receiver.result will be used by the block to store
              block_args = [receiver = OpenStruct.new]

              # prepare all the other block arguments
              args.times{|i| block_args << value_text(i)}

              # now call the given block and return the value using +result+
              block.call(*block_args)
              result(receiver.result)
            end

          end

          org.sqlite.Function.create(self.connection, name, generic_function.new)
        end

      end
    end
  end
end
