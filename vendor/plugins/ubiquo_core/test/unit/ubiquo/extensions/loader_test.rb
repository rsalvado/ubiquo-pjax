require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Extensions::LoaderTest < ActiveSupport::TestCase

  # Mock classes, with namespace to test the general case
  class Test::MyClass; end
  class Test::OtherClass; end
  module Test::MyModule
    def my_method; end
  end

  def test_append_methods_should_trigger_include_when_defined
    Ubiquo::Extensions::Loader.methods.each do |method|
      Test::MyClass.expects(method).with(Test::MyModule)
      Ubiquo::Extensions::Loader.send("append_#{method}", 'Test::MyClass', Test::MyModule)
    end
  end

  def test_append_methods_should_schedule_automatic_inclusion_when_defined_after_with_const_set
    Test.send('remove_const', 'MyClass')
    Ubiquo::Extensions::Loader.append_include('Test::MyClass', Test::MyModule)
    Test.const_set('MyClass', Class.new)
    assert Test::MyClass.instance_methods.include?('my_method')
  end

  def test_append_methods_should_schedule_automatic_inclusion_when_defined_after_with_normal_def
    Test.send('remove_const', 'MyClass')
    Ubiquo::Extensions::Loader.append_include('Test::MyClass', Test::MyModule)
    Test.class_eval "class MyClass; end"
    assert Test::MyClass.instance_methods.include?('my_method')
  end

  def test_append_methods_should_allow_inclusion_in_other_classes
    Ubiquo::Extensions::Loader.append_include('Test::MyClass', Test::MyModule)
    Test::OtherClass.class_eval do
      Ubiquo::Extensions.load_extensions_for Test::MyClass, self
    end
    assert Test::OtherClass.instance_methods.include?('my_method')
  end

end
