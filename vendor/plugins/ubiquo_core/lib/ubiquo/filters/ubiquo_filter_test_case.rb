# -*- coding: utf-8 -*-
module Ubiquo
  module Filters

    # A helper class sets a proper context to be able to execute the filters.
    class FakeContext < ::ActionView::Base

      include ::Ubiquo::Helpers::CoreUbiquoHelpers

      attr_accessor :params

      def initialize
        params = {
          'controller' => 'tests',
          'action' => 'index'
        }
        @params = HashWithIndifferentAccess.new(params)
      end

      def url_for(options)
        "http://example.com/tests"
      end

    end

    # A helper model to be able to execute filters.
    class FilterTestModel
      def self.create
        table = 'filter_tests'
        conn = ::ActiveRecord::Base.connection

        conn.create_table table.to_sym do |t|
          t.string   :title
          t.text     :description
          t.datetime :published_at
          t.boolean  :status, :default => false
          t.timestamps
        end unless conn.tables.include?(table)

        model = table.classify
        Object.const_set(model, Class.new(::ActiveRecord::Base)) unless Object.const_defined? model
        model.constantize
      end

    end

    # Helper class to easy the filter testing.
    class UbiquoFilterTestCase < ::ActionView::TestCase

      include ::Ubiquo::Filters
      include ::Ubiquo::Helpers::CoreUbiquoHelpers

      def initialize(*args)
        ::ActionController::Routing::Routes.draw { |map| map.resources :tests }
        @model = FilterTestModel.create
        @model.delete_all
        load_test_data
        @context = FakeContext.new
        super(*args)
      end

      def load_test_data
        [
         { :title => 'Yesterday loot was cool',
           :description => 'òuch réally?',
           :published_at => Date.today,
           :status => true
         },
         { :title => 'Today is the new yesterday. NIÑA',
           :description => 'bah loot',
           :published_at => Date.today,
           :status => false
         },
         { :title => 'Tíred',
           :description => 'stop',
           :published_at => Date.tomorrow,
           :status => false
         }
        ].each { |attrs| @model.create(attrs) }
      end

    end

  end
end
