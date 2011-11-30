module UbiquoI18n
  module Adapters
    autoload :SchemaStatements, "ubiquo_i18n/adapters/schema_statements"
  end
end


ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, UbiquoI18n::Adapters::SchemaStatements)
