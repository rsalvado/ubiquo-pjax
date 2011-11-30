module Ubiquo
  module Tasks
    module Database

      def fixture_path(fixture_name=nil)
        if ENV["FIXTURES_DIR"]
          pathdir = File.dirname(ENV["FIXTURES_DIR"])
        else
          pathdir= case ENV["RAILS_ENV"]
                   when "test"
                     Rails.root.join('test','fixtures')
                   when "production"
                     Rails.root.join('db','bootstrap')
                   when "preproduction"
                     Rails.root.join('db','pre_bootstrap')
                   else
                     Rails.root.join('db','dev_bootstrap')
                   end
        end
        path = pathdir.to_s
        path += "/#{fixture_name}.yml" if fixture_name
        if File.exists?(pathdir)
          raise StandardError.new("Path %s exists and is a file." % pathdir) if File.file?(pathdir)
        else
          p "Creating dir %s" % pathdir
          FileUtils.mkdir_p(pathdir)
        end
        path
      end

      def write_yaml_fixtures_to_file(table_name)
        # fixture id generator
        i = '0'
        fixture_id = lambda { |fixture| fixture['id'] || i.succ! }

        # generate and write the data
        File.open(fixture_path(table_name), 'w' ) do |file|
          data = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name}")
          file.write ordered_yaml(data.inject({}) { |hash, record|
            hash["#{table_name}_#{"%0.3i" % fixture_id.call(record)}"] = record
            hash
          })
        end
      end

      def write_all_yaml_fixtures_to_file
        skip_tables = ["schema_info", "schema_migrations"]
        (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
          write_yaml_fixtures_to_file(table_name)
        end
      end

      def import_table_fixture(table)
        filename = fixture_path(table)
        success = Hash.new
        success[table.to_sym] ||= 0
        records = YAML::load( File.open(filename))

        records.sort.each do |r|
          row = r[1]
          columns = []
          values = []

          row.each_pair do |column, value|
            if column.to_sym
              columns << ActiveRecord::Base.connection.quote_column_name(column)
              values << ActiveRecord::Base.connection.quote(value)
            else
              p "Column not found" + column.to_s
            end
          end

          insert_sql = "INSERT INTO #{table} (" + columns.join(', ') + ") VALUES (" + values.join(', ') + ")"

          begin
            if ActiveRecord::Base.connection.execute(insert_sql)
              success[table.to_sym] = (success[table.to_sym] ? success[table.to_sym] + 1 : 1)
            end
          rescue
            p "#{table} failed to import: " + insert_sql
          end
        end

        p "Total of #{success[table.to_sym]} #{table} records imported successfully"
      end

      def import_model_fixture(model)
        filename = fixture_path(model.tableize)
        success = Hash.new
        success[model.to_sym] ||= 0
        records = YAML::load( File.open(filename))
        @model = Class.const_get(model)
        @model.transaction do
          records.sort.each do |r|
            row = r[1]
            @new_model = @model.new

            row.each_pair do |column, value|
              if column.to_sym
                @new_model.send(column + '=', value)
              else
                p "Column not found" + column.to_s
              end
            end

            begin
              if @new_model.save
                success[model.to_sym] = (success[model.to_sym] ? success[model.to_sym] + 1 : 1)
              end
            rescue
              p "#{@new_model.class.to_s} failed to import: " + r.inspect
              p @new_model.errors.inspect
            end
          end

          p "Total of #{success[model.to_sym]} #{@new_model.class.to_s} records imported successfully"
        end
        fix_sequence_consistency [model.tableize]
      end

      def join_table_names(table_names, model_names, group_names)
        tables = table_names.to_s.split(',')
        model_names.to_s.split(',').each do |model|
          tables << model.tableize
        end
        process_groups(group_names) do |table|
          tables << table
        end
        tables.uniq
      end

      # This is like Hash.to_yaml except that it sorts by key before converting
      def ordered_yaml(data)
        YAML::quick_emit( data.object_id, {} ) do |out|
          out.map( data.taguri, data.to_yaml_style ) do |map|
            data.sort.each do |k, v|
              map.add( k, v )
            end
          end
        end
      end

      def process_groups(group_list)
        group_list.to_s.split(',').each do |group|
          tables = Ubiquo::Config.get(:model_groups)[group.to_sym]
          tables.each do |table|
            yield table
          end if tables
          fix_sequence_consistency tables
        end
      end

      # If any of these "tables" has a sequence field, make sure that the next
      # value that will be returned does not conflict with the imported fixtures
      def fix_sequence_consistency(tables)
        (tables || []).each do |table_name|
          ActiveRecord::Base.connection.list_sequences(table_name.to_s + "_$").each do |sequence|
            ActiveRecord::Base.connection.reset_sequence_value(sequence)
          end
        end
      end
    end
  end
end
