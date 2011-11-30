require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Extensions::DistinctOptionTest < ActiveSupport::TestCase

  def setup
    @options = prepare_for_distinct_test
  end
  def test_distinct_option_default_behaviour
    results = TestOnlyModel.all(@options.except(:distinct))
    assert_equal 2, results.size
  end

  def test_distinct_option_enabled_in_find
    results = TestOnlyModel.all(@options)
    assert_equal 1, results.size, ':distinct option does not work as expected'
  end

  def test_distinct_option_enabled_in_scope
    results = TestOnlyModel.scoped(@options)
    assert_equal 1, results.size, ':distinct option does not work as expected in scopes'
  end

  def test_distinct_option_does_not_affect_order_and_select
    complex_order = 'name DESC, test_only_models.id ASC, test_only_model_twos.title'
    %w{all scoped}.each do |method|
      results = TestOnlyModel.send(method,
        @options.merge(:select => 'test_only_models.id', :order => complex_order)
      )
      assert_equal 1, results.size
      assert_raise ActiveRecord::MissingAttributeError do
        results.first.name # only :id has been loaded (preserves :select)
      end
    end
  end

  protected

  def prepare_for_distinct_test
    t = TestOnlyModel.create(:name => 'test')
    2.times do
      t.test_only_model_twos << TestOnlyModelTwo.create
    end
    {:joins => [:test_only_model_twos], :distinct => true}
  end

end
