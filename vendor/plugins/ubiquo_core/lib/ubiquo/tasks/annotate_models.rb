module Ubiquo
  module Tasks
    module AnnotateModels

      MODEL_DIR      = Rails.root.join('app', 'models')
      PLUGIN_DIR     = Rails.root.join('vendor', 'plugins')
      MODEL_REL_DIR  = Rails.root.join('app', 'models')
      FIXTURE_DIR    = Rails.root.join('test', 'fixtures')
      RSPEC_DIR      = Rails.root.join('spec', 'models')
      RSPEC_FIXTURES = Rails.root.join('spec', 'fixtures')

      PREFIX = "== Schema Information"

      # Simple quoting for the default column value
      def quote(value)
        case value
        when NilClass                 then "NULL"
        when TrueClass                then "TRUE"
        when FalseClass               then "FALSE"
        when Float, Fixnum, Bignum    then value.to_s
          # BigDecimals need to be output in a non-normalized form and quoted.
        when BigDecimal               then value.to_s('F')
        else
          value.inspect
        end
      end

      # Use the column information in an ActiveRecord class
      # to create a comment block containing a line for
      # each column. The line contains the column name,
      # the type (and length), and any optional attributes
      def get_schema_info(klass, header)
        info = "# #{header}\n#\n"
        info << "# Table name: #{klass.table_name}\n#\n"

        max_size = klass.column_names.collect{|name| name.size}.max + 1
        klass.columns.each do |col|
          attrs = []
          attrs << "default(#{quote(col.default)})" if col.default
          attrs << "not null" unless col.null
          attrs << "primary key" if col.name == klass.primary_key

          col_type = col.type.to_s
          if col_type == "decimal"
            col_type << "(#{col.precision}, #{col.scale})"
          else
            col_type << "(#{col.limit})" if col.limit
          end
          info << sprintf("#  %-#{max_size}.#{max_size}s:%-15.15s %s", col.name, col_type, attrs.join(", ")).rstrip
          info << "\n"
        end

        info << "#\n\n"
      end

      # Add a schema block to a file. If the file already contains
      # a schema info block (a comment starting
      # with "Schema as of ..."), remove it first.

      def annotate_one_file(file_name, info_block)
        if File.exist?(file_name)
          content = File.read(file_name)

          # Remove old schema info
          content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')

          # Write it back
          File.open(file_name, "w") { |f| f.puts info_block + content }
        end
      end

      # Given the name of an ActiveRecord class, create a schema
      # info block (basically a comment containing information
      # on the columns and their types) and put it at the front
      # of the model and fixture source files.

      def annotate(path, klass, header)
        info = get_schema_info(klass, header)

        model_file_name = File.join(path, klass.name.underscore + ".rb")
        annotate_one_file(model_file_name, info)

        if Rails.root.join('spec')
          rspec_file_name = File.join(RSPEC_DIR, klass.name.underscore + "_spec.rb")
          annotate_one_file(rspec_file_name, info)

          rspec_fixture = File.join(RSPEC_FIXTURES, klass.table_name + ".yml")
          annotate_one_file(rspec_fixture, info)
        end

        Dir.glob(File.join(FIXTURE_DIR, "**", klass.table_name + ".yml")) do | fixture_file_name |
          annotate_one_file(fixture_file_name, info)
        end
      end

      # Return a list of the model files to annotate. If we have
      # command line arguments, they're assumed to be either
      # the underscore or CamelCase versions of model names.
      # Otherwise we take all the model files in the
      # app/models and vendor/plugins/xxxx/app/models directory.
      def get_model_names
        models = ARGV.dup
        models.shift

        if models.empty?
          Dir.chdir(MODEL_DIR) do
            models = {MODEL_DIR => Dir["**/*.rb"]}
          end
          Dir.chdir(PLUGIN_DIR) do
            Dir["*"].each do |plugin|
              if plugin =~ /ubiquo/ && File.exists?(File.join(plugin, MODEL_REL_DIR))
                Dir.chdir(File.join(plugin, MODEL_REL_DIR)) do
                  models[File.join(PLUGIN_DIR, plugin, MODEL_REL_DIR)] = Dir["**/*.rb"]
                end
              end
            end
          end
        end
        models
      end

      # We're passed a name of things that might be
      # ActiveRecord models. If we can find the class, and
      # if its a subclass of ActiveRecord::Base,
      # then pas it to the associated block

      def do_annotations
        header = PREFIX.dup
        version = ActiveRecord::Migrator.current_version rescue 0
        if version > 0
          header << "\n# Schema version: #{version}"
        end

        get_model_names.each_pair do |path, models|
          models.each do |model|
            class_name = model.sub(/\.rb$/,'').camelize
            begin
              klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
              if klass < ActiveRecord::Base && !klass.abstract_class?
                puts "Annotating #{class_name}"
                annotate(path, klass, header)
              else
                puts "Skipping #{class_name}"
              end
            rescue Exception => e
              puts "Unable to annotate #{class_name}: #{e.message}"
            end
          end

        end
      end
    end
  end
end
