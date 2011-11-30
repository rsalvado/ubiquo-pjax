module UbiquoVersions
  module Adapters
    autoload :SchemaStatements, "ubiquo_versions/adapters/schema_statements"
  end
end


ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, UbiquoVersions::Adapters::SchemaStatements)
