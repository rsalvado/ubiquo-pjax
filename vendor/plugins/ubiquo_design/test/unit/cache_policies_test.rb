require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::CachePoliciesTest < ActiveSupport::TestCase

  def teardown
    UbiquoDesign::CachePolicies.clear(:test)
  end

  def test_should_initialize_structure
    UbiquoDesign::CachePolicies.define(:test) {}
    assert_equal({}, UbiquoDesign::CachePolicies.get(:test))
  end

  def test_should_store_model
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => 'Page'
      }
    end
    assert_equal(['Page'], UbiquoDesign::CachePolicies.get(:test)[:widget][:models].keys)
  end

  def test_should_store_self_key
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => :self
      }
    end
    assert UbiquoDesign::CachePolicies.get(:test)[:widget][:self]
  end

  def test_should_store_self_key_by_default_on_definition
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => 'Page'
      }
    end
    assert UbiquoDesign::CachePolicies.get(:test)[:widget][:self]
  end

  def test_should_store_proc
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => lambda{'result'}
      }
    end
    assert_equal 'result', UbiquoDesign::CachePolicies.get(:test)[:widget][:procs].first.call
  end


  def test_should_store_array_of_elements
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => [{'Page' =>  {:id => :id}}, {'Widget' => {:name => :name, :result => lambda{'result'}}}]
      }
    end
    assert_equal [{:name => :name}], UbiquoDesign::CachePolicies.get(:test)[:widget][:models]['Widget'][:params]
    assert_equal [{:id => :id}], UbiquoDesign::CachePolicies.get(:test)[:widget][:models]['Page'][:params]
    assert_equal ['Page', 'Widget'], UbiquoDesign::CachePolicies.get(:test)[:widget][:models].keys.sort
    assert_equal 'result', UbiquoDesign::CachePolicies.get(:test)[:widget][:models]['Widget'][:procs].first.first.call
  end

  def test_should_clear
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :widget => :id
      }
    end
    UbiquoDesign::CachePolicies.clear(:test)
    assert_equal({}, UbiquoDesign::CachePolicies.get(:test))
  end

  def test_should_get_by_model
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :page => 'Page',
        :widget => 'Widget',
        :free => 'Free'
      }
    end
    assert_equal([[], [:page]], UbiquoDesign::CachePolicies.get_by_model(Page.new, :test))
    assert_equal_set([:free, :widget], UbiquoDesign::CachePolicies.get_by_model(Free.new, :test)[1])
  end
end
