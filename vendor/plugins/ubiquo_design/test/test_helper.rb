require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"
require 'mocha'

class ActiveSupport::TestCase
end

class TestWidget < Widget
  self.allowed_options = :title, :description
end

if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end
