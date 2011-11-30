module Ubiquo
  module Adapters
  end
end

connection = begin
  ActiveRecord::Base.connection
rescue MissingSourceFile, StandardError
  false
end
if connection

  included_module = case connection.class.to_s
    when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
      Ubiquo::Adapters::Postgres
    when "ActiveRecord::ConnectionAdapters::SQLite3Adapter"
      Ubiquo::Adapters::Sqlite
    when "ActiveRecord::ConnectionAdapters::MysqlAdapter"
      Ubiquo::Adapters::Mysql
    else
      nil
  end

  included_module ||= case connection.config[:adapter]
    when "mysql"
      Ubiquo::Adapters::Mysql
    when "postgresql"
      Ubiquo::Adapters::Postgres
    when "sqlite3"
      Ubiquo::Adapters::Sqlite
    else nil
  end rescue nil


  raise "Only PostgreSQL, MySQL and SQLite supported" if  included_module == nil

  ActiveRecord::Base.connection.class.send(:include, included_module)
  ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, Ubiquo::Adapters::SequenceDefinition)
  ActiveRecord::ConnectionAdapters::Table.send(:include, Ubiquo::Adapters::SequenceDefinition)
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Ubiquo::Adapters::SchemaStatements)
end
