module Ubiquo
  module Extensions
    module TestCase

      def self.included(klass)
        klass.extend(ClassMethods)
        klass.send(:include, ConnectorsTesting)
      end

      # Like assert_equal but test that expected and actual sets are equal
      def assert_equal_set(expected, actual, *args)
        assert_equal(expected.to_set, actual.to_set, *args)
      end

      module ConnectorsTesting

        def save_current_connector(plugin)
          @old_connector ||= {}
          @old_connector[plugin] = plugin_class(plugin)::Connectors::Base.current_connector
        end

        def reload_old_connector(plugin)
          @old_connector[plugin].load!
        end

        # Prepares the proper mocks for a hook that will be using controller features
        def mock_controller(controller)
          for_controller(controller) do
            mock_params
            mock_session
            mock_routes
            mock_response
          end
        end

        def mock_params params = {}, controller = nil
          (controller || stubbed_controller).any_instance.stubs(:params).returns(params)
        end

        def mock_session session = {}, controller = nil
          (controller || stubbed_controller).any_instance.stubs(:session).returns(session)
        end

        def mock_routes controller = nil
          (controller || stubbed_controller).any_instance.stubs(:request).returns(ActionController::TestRequest.new)
          Ubiquo::CategoriesController.any_instance.stubs(:redirect_to)
          Ubiquo::CategoriesController.any_instance.stubs(:url_for).returns('')
        end

        def mock_response controller = nil
          (controller || stubbed_controller).any_instance.stubs(:redirect_to)
        end

        # Prepares the proper mocks for a hook that will be using helper features
        def mock_helper(plugin)
          # we stub well-known usable helper methods along with particular connector added methods
          stubs = {
            :params => {}, :t => '', :link_to => ''
          }.merge(plugin_class(plugin)::Connectors::Base.current_connector.mock_helper_stubs || {})

          stubs.each_pair do |method, retvalue|
            connector = plugin_class(plugin)::Connectors::Base.current_connector
            helpers = connector.constants.select do |name|
              connector.const_get(name).constants.include?('Helper')
            end
            helpers.each do |helper|
              connector.const_get(helper)::Helper.stubs(method).returns(retvalue)
            end
          end
        end

        protected

        def plugin_class(plugin)
          plugin.to_s.camelize.constantize
        end

        def for_controller(controller)
          @stubbed_controller = controller
          yield
        end

        def stubbed_controller
          @stubbed_controller
        end
      end

      module ClassMethods
        include Ubiquo::Tasks::Files

        # Loads the special set of ubiquo fixtures
        # Note that if you are firing a TestCase that uses ubiquo fixtures,
        # all the TestCases will be affected and using the ubiquo fixtures path
        def use_ubiquo_fixtures

          fixture_set_path = Rails.root.join('tmp', 'ubiquo_fixtures')
          install_ubiquo_fixtures unless File.exists?(fixture_set_path)

          fixture_files = Dir.entries(fixture_set_path).reject {|e| e =~ /^\./ || e !~ /\.yml$/}
          raise "No fixtures found in #{fixture_set_path}, have you run rake test:fixture_sets:scan?" if fixture_files.empty?

          # sets the global fixture path to the ubiquo one
          ActiveSupport::TestCase.fixture_path = fixture_set_path

          fixture_symbols = fixture_files.map {|f| f.gsub('.yml', '').to_sym}
          # prepares the accessors and requires the needed classes
          fixtures(*fixture_symbols)
        end

        # Tests all the test methods inside the given block for each of the available +plugin+ connectors
        # You must have a Ubiquo::Config key :available_connectors for your plugin
        # in order to use this. Also, the convention is that your connectors will
        # be in a +plugin+.camelize::Connectors module
        def test_each_connector(plugin)
          Ubiquo::Config.context(plugin).get(:available_connectors).each do |conn|

            (class << self; self end).class_eval do
              eval <<-CONN
                def test_with_connector name, &block
                  block_with_connector_load = Proc.new{
                    "#{plugin.to_s.camelize}::Connectors::#{conn.to_s.camelize}".constantize.load!
                    block.bind(self).call
                  }
                  test_without_connector "#{conn}_\#{name}", &block_with_connector_load
                end
              CONN

              unless instance_methods.include?('test_without_connector')
                alias_method :test_without_connector, :test
              end
              alias_method :test, :test_with_connector
            end
            yield
          end
        end
      end
    end
  end
end

require 'mocha'
# Improvement for Mocha's Mock: stub_everything with a default return value other than nil.
class Mocha::Mock

  def stub_default_value= value
    @everything_stubbed_default_value = value
  end

  if !self.instance_methods.include?(:method_missing_with_stub_default_value.to_s)

    def method_missing_with_stub_default_value(symbol, *arguments, &block)
      value = method_missing_without_stub_default_value(symbol, *arguments, &block)
      if !@expectations.match_allowing_invocation(symbol, *arguments) && !@expectations.match(symbol, *arguments) && @everything_stubbed
        @everything_stubbed_default_value
      else
        value
      end
    end

    alias_method_chain :method_missing, :stub_default_value

  end

end
