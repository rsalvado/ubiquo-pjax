require File.dirname(__FILE__) + "/../../../../test/test_helper.rb"
require 'mocha'

# Create a test file for tests
def test_file(contents = "contents", ext = "txt")
  Tempfile.new("test." + ext).tap do |file|
    file.write contents
    file.flush
  end
end

def sample_image
  File.open(File.join( File.dirname(__FILE__),
            "/fixtures/resources/sample.png"))
end

def mock_asset_params params = {}
  mock_params(params, Ubiquo::AssetsController)
end

def mock_assets_controller
  mock_controller Ubiquo::AssetsController
end

def mock_media_helper
  mock_helper(:ubiquo_media)
end

class AssetType # Using this model because is very simple and has no validations
  media_attachment :simple
  media_attachment :multiple, :size => :many
  media_attachment :sized, :size => 2
  media_attachment :all_types, :types => :ALL
  media_attachment :some_types, :types => %w{audio video}
end


if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end
