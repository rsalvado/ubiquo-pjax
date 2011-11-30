require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::ConfigTest < ActiveSupport::TestCase
  include Ubiquo::Extensions::ConfigCaller
  def setup
    @old_configuration = Ubiquo::Config.configuration
    Ubiquo::Config.configuration = Ubiquo::Config.new_context_options
  end
  
  def teardown
    Ubiquo::Config.configuration = @old_configuration
  end

  def test_add_new_option
    assert_nothing_raised do
      Ubiquo::Config.add(:new_option)
      Ubiquo::Config.set(:new_option, 1)
      assert_equal Ubiquo::Config.get(:new_option), 1
    end
  end

  def test_add_new_option_only_once
    assert_nothing_raised do
      Ubiquo::Config.add(:new_option)
    end

    assert_raises(Ubiquo::Config::AlreadyExistingOption) do
      Ubiquo::Config.add(:new_option)
    end
  end

  def test_needs_to_add_for_setting_a_value
    assert_raises(Ubiquo::Config::OptionNotFound) do
      Ubiquo::Config.set(:new_option, 1)
    end
  end

  def test_needs_to_add_for_setting_a_default_value
    assert_raises(Ubiquo::Config::OptionNotFound) do
      Ubiquo::Config.set_default(:new_option, 1)
    end
  end

  def test_usage_of_default_value
    assert_nothing_raised do
      Ubiquo::Config.add(:new_option)
      Ubiquo::Config.set_default(:new_option, 1)
      assert_equal Ubiquo::Config.get(:new_option), 1

      Ubiquo::Config.set(:new_option, 2)
      assert_equal Ubiquo::Config.get(:new_option), 2

      Ubiquo::Config.set_default(:new_option, 3)
      assert_equal Ubiquo::Config.get(:new_option), 2
    end
  end

  def test_massive_add
    assert_nothing_raised do
      Ubiquo::Config.add do |config|
        config.a = 1
        config.b = 2
        config.c = 3
      end

      assert_equal Ubiquo::Config.get(:a), 1
      assert_equal Ubiquo::Config.get(:b), 2
      assert_equal Ubiquo::Config.get(:c), 3
    end
  end

  def test_massive_default_options
    Ubiquo::Config.add(:a)
    Ubiquo::Config.add(:b)
    Ubiquo::Config.add(:c)
    assert_nothing_raised do
      Ubiquo::Config.set_default do |config|
        config.a = 1
        config.b = 2
        config.c = 3
      end

      assert_equal Ubiquo::Config.get(:a), 1
      assert_equal Ubiquo::Config.get(:b), 2
      assert_equal Ubiquo::Config.get(:c), 3
    end
  end

  def test_massive_default_options
    Ubiquo::Config.add(:a)
    Ubiquo::Config.add(:b)
    Ubiquo::Config.add(:c)
    assert_nothing_raised do
      Ubiquo::Config.set do |config|
        config.a = 1
        config.b = 2
        config.c = 3
      end

      assert_equal Ubiquo::Config.get(:a), 1
      assert_equal Ubiquo::Config.get(:b), 2
      assert_equal Ubiquo::Config.get(:c), 3
    end
  end
  
  def test_context_creation_required_to_use_it
    assert !Ubiquo::Config.context_exists?(:new_context)
    assert_raises(Ubiquo::Config::ContextNotFound) do
       Ubiquo::Config.context(:new_context).add(:a)
    end
  end
  
  def test_block_context_option
    Ubiquo::Config.create_context(:new_context)
    Ubiquo::Config.add(:a, 1) # Global option
    Ubiquo::Config.context(:new_context) do |ubiquo_config|
      ubiquo_config.add(:a, 2)
    end
    
    Ubiquo::Config.context(:new_context) do |ubiquo_config|
      assert_equal ubiquo_config.get(:a), 2
    end
    assert_equal Ubiquo::Config.get(:a), 1
  end
  
  def test_inline_context_option
    Ubiquo::Config.create_context(:new_context)
    Ubiquo::Config.add(:a, 1) # Global option
    Ubiquo::Config.context(:new_context).add(:a, 2)
    
    assert_equal 2, Ubiquo::Config.context(:new_context){ |c| c.get(:a)}
    assert_equal 1, Ubiquo::Config.get(:a)
  end
  
  def test_caller
    Ubiquo::Config.add(:a, lambda{"return this"})
    assert_equal "return this", self.ubiquo_config_call(:a)
  end
  
  def test_caller_in_current_binding
    Ubiquo::Config.add(:a, lambda{dummy_method})
    assert_equal dummy_method,  self.ubiquo_config_call(:a)
  end
  
  def test_caller_with_parameters
    Ubiquo::Config.add(:a, lambda{|options| dummy_method(options)})
    assert_equal dummy_method({:word => "man"}),  self.ubiquo_config_call(:a, {:word => "man"})
  end
  
  def test_caller_with_parameters_from_external_context
    ExternalContext.test
    assert_equal dummy_method({:word => "man"}),  self.ubiquo_config_call(:a, {:word => "man"})
  end
  
  def test_caller_with_symbol
    Ubiquo::Config.add(:a, :dummy_method)
    assert_equal dummy_method, self.ubiquo_config_call(:a)
  end
  
  def test_caller_with_symbol_and_parameters
    Ubiquo::Config.add(:a, :dummy_method)
    assert_equal dummy_method({:word => "man"}), self.ubiquo_config_call(:a, {:word => "man"})
  end
  
  def test_caller_with_context
    Ubiquo::Config.create_context(:new_context)
    Ubiquo::Config.context(:new_context).add(:a, lambda{|options|
        dummy_method(options)
      })
  
    assert_equal dummy_method({:word => "man"}),  self.ubiquo_config_call(:a, {:context => :new_context, :word => "man"})
  end
  
  def test_inheritance
    Ubiquo::Config.add(:a, "hello")
    Ubiquo::Config.add(:b)
    assert_raises(Ubiquo::Config::ValueNeverSetted) do
      Ubiquo::Config.get(:b)
    end
    Ubiquo::Config.add_inheritance(:b, :a)

    assert_nothing_raised do
      assert_equal "hello", Ubiquo::Config.get(:b)
    end
    
    Ubiquo::Config.set(:a, "Bye")
    assert_nothing_raised do
      assert_equal "Bye", Ubiquo::Config.get(:b)
    end
    
    Ubiquo::Config.set(:b, "Hello again")
    assert_nothing_raised do
      assert_equal "Hello again", Ubiquo::Config.get(:b)
    end
  end
  
  def test_inheritance_in_different_context
    Ubiquo::Config.create_context(:new_context_1)
    Ubiquo::Config.create_context(:new_context_2)
    
    Ubiquo::Config.context(:new_context_1).add(:a, "hello")
    Ubiquo::Config.context(:new_context_2).add(:b)    

    assert_raises(Ubiquo::Config::ValueNeverSetted) do
      Ubiquo::Config.context(:new_context_2).get(:b)
    end
    Ubiquo::Config.context(:new_context_2).add_inheritance(:b, :new_context_1 =>:a)
    assert_nothing_raised do
      assert_equal "hello", Ubiquo::Config.context(:new_context_2).get(:b)
    end
  end
  
  def test_inheritance_in_context_to_base
    Ubiquo::Config.create_context(:new_context)
    
    Ubiquo::Config.add(:a, "hello")
    Ubiquo::Config.context(:new_context).add(:b)    

    assert_raises(Ubiquo::Config::ValueNeverSetted) do
      Ubiquo::Config.context(:new_context).get(:b)
    end
    Ubiquo::Config.context(:new_context).add_inheritance(:b, :a)
    assert_nothing_raised do
      assert_equal "hello", Ubiquo::Config.context(:new_context).get(:b)
    end
  end
  
  
  
  def dummy_method(options = {})
    options = {:word => "world"}.merge(options)
    "hello #{options[:word]}"
  end
end

class ExternalContext
  def self.test
    Ubiquo::Config.add(:a, lambda{|options| self.dummy_method(options)})
  end
end
