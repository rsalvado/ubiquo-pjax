require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"

if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end

require File.dirname(__FILE__) + '/relation_helper'
require 'rake' # For cron job testing
