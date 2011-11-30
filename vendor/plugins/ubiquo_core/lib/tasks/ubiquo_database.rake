namespace :ubiquo do
  namespace :db do
    desc "Reset the current database schema and imports devel data fixtures (only in development mode)"
    task :reset do
      begin
        gem 'rake', '>0.8'
      rescue Gem::LoadError => load_error
        $stderr.puts "Please update the rake gem to at least 0.8.1 version."
        exit 1
      end
      if Rails.env.development?
        # Drops and recreates database
        Rake::Task['ubiquo:db:recreate'].invoke

        # Create the db structure and fill it
        Rake::Task['ubiquo:db:prepare'].invoke

        puts "Done :-)"
      else
        puts "This task should only be run in a development environment."
      end
    end

    task :recreate => ['db:drop', 'db:create']

    task :prepare => :environment do
        # forward, comrades, to the future!
        ENV.delete('VERSION')
        Rake::Task["db:migrate"].execute

        # Dump schema.rb (some devs like it)
        Rake::Task["db:schema:dump"].execute

        # preparing test database
        Rake::Task["db:test:prepare"].execute

        puts "Importing fixtures into development database... "
        ENV['DELETE'] = 'yes'
        Rake::Task['ubiquo:db:fixtures:import'].invoke

        # Call seeds
        puts "Invoking db:seed task... "
        Rake::Task['db:seed'].invoke
    end

    desc "Alias task for ubiquo:db:reset"
    task :init => "ubiquo:db:reset"

    desc "Fix the sequence fields consistency for the tables of the given [TABLES=foos[,bars,lands]] [MODELS=Foo[,Bar,Land]] [GROUPS=Group1[,Group2,Group3]]"
    task :fix_sequences => :environment do
      include Ubiquo::Tasks::Database
      ActiveRecord::Base.establish_connection
      tables = join_table_names(ENV['TABLES'], ENV['MODELS'], ENV['GROUPS'])
      tables = ActiveRecord::Base.connection.tables if tables.blank?
      puts tables.inspect
      fix_sequence_consistency(tables)
    end

    namespace :fixtures do
      desc "use export [TABLES=foos[,bars,lands]] [MODELS=Foo[,Bar,Land]] [GROUPS=Group1[,Group2,Group3]] to create YAML fixtures from data in an existing database.\n" +
        "Defaults to development database. Set RAILS_ENV to override. "

      task :export => :environment do
        include Ubiquo::Tasks::Database

        ActiveRecord::Base.establish_connection

        # Collect table names to export
        tables = join_table_names(ENV['TABLES'], ENV['MODELS'], ENV['GROUPS'])
        if tables.blank?
          # No specific tables means that we'll export everything
          write_all_yaml_fixtures_to_file
        else
          tables.each do |table_name|
            write_yaml_fixtures_to_file(table_name)
          end
        end
      end

      desc "use import [TABLES=foos[,bars,lands]] [MODELS=Foo[,Bar,Land]] [GROUPS=group1[,group2,group3]] to import YAML fixtures into an existing database.\n" +
        "Add DELETE=yes to clear previously existing db fixtures. \n" +
        "Defaults to development database. Set RAILS_ENV to override. "

      task :import => :environment do
        require 'active_record/fixtures'
        include Ubiquo::Tasks::Database

        ActiveRecord::Base.establish_connection

        if ENV['DELETE'] == 'yes'
          # Collect table names to import
          tables = join_table_names(ENV['TABLES'], ENV['MODELS'], ENV['GROUPS'])
          # No specific tables means that we'll import everything
          tables = Dir.glob(fixture_path('*')).map{ |file| File.basename(file, '.*') } if tables.blank?

          # Create fixtures and print result summary
          fixtures = Fixtures.create_fixtures(fixture_path, tables || [])

          # Print results
          # if there is only one kind of fixtures created, create_fixtures returns an array with a missing dimension
          fixtures = [fixtures] unless fixtures[0]
          results = fixtures.map do |group|
            "#{group.size} #{group.flatten.last.model_class.to_s.tableize}" if group.flatten.last
          end
          if fixtures
            p 'Created fixtures: ' + results.compact.join(', ')
          else
            p 'No fixtures to import'
          end

        else
          unless ENV['TABLES'] || ENV['MODELS'] || ENV['GROUPS']
            tables = Dir.glob(fixture_path('*')).map{ |file| File.basename(file, '.*') }
          else
            tables = ENV['TABLES'].to_s.split(',')
            # models are created separately with model.new / model.save
            ENV['MODELS'].to_s.split(',').each do |model|
              import_model_fixture(model)
            end
            process_groups(ENV['GROUPS']) do |table|
              import_table_fixture(table)
            end
          end
          tables.each do |table|
            import_table_fixture(table)
          end
        end
        fix_sequence_consistency tables
      end

    end
  end

end
