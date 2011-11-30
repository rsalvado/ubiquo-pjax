require 'ostruct'

#Ubiquo::Config offers a place where store configuration variables.
#
#It stores all the values in a data structure like that:
# configuration = {
#  <context_name> => {
#    :allowed_options => [
#      <option_1>,
#      <option_2>,
#      ...
#      <option_N>,
#    ]
#    :default_values => {
#      <option_1> => <value_1>,
#      <option_2> => <value_2>,
#      ...
#      <option_N> => <value_N>,
#    }
#    :values => {
#      <option_1> => <value_1>,
#      <option_2> => <value_2>,
#      ...
#      <option_N> => <value_N>,
#    },
#    :inherited_values => {
#      <option_1> => <lambda_1>,
#      <option_2> => <lambda_2>,
#      ...
#      <option_N> => <lambda_N>,
#    }
#  }
# }
#
#See public methods to know how to use.
class Ubiquo::Config

  cattr_accessor :configuration

  #Adds an option to the current context (default :BASE). Default value is optional.
  #Example:
  # >> Ubiquo::Config.add(:new_option, 1)
  # >> Ubiquo::Config.get(:new_option)
  # => 1
  #
  #Can be used with a block.
  #Example:
  # >> Ubiquo::Config.add do |configurator|
  #      configurator.option_1 = 1
  #      configurator.option_2 = 2
  #    end
  #
  # >> Ubiquo::Config.get(:option_1)
  # => 1
  # >> Ubiquo::Config.get(:option_2)
  # => 2

  def self.add(name = nil, default_value = nil, &block)
    if block_given?
      block_assignment(&block).each do |name, default_value|
        self.add(name.to_sym, default_value)
      end
    else
      raise InvalidOptionName if !check_valid_name(name)
      raise AlreadyExistingOption if configuration[self.current_context][:allowed_options].include?(name)
      name = name.to_sym
      configuration[self.current_context][:default_values][name] = default_value if !default_value.nil?
      configuration[self.current_context][:allowed_options] << name
    end
  end

  def self.add_inheritance(name, inherited_value)
    raise InvalidOptionName if !check_valid_name(name)
    raise OptionNotFound if !self.option_exists?(name)
    name = name.to_sym

    proc = case inherited_value
           when Hash
             lambda{ Ubiquo::Config.context(inherited_value.keys.first).get(inherited_value.values.first)}
           when String, Symbol
             lambda{ Ubiquo::Config.context(:BASE).get(inherited_value)}
           end

    configuration[self.current_context][:inherited_values][name] = proc
  end

  #Set a default value to an existent option of the current context( default :BASE).
  #Example:
  #  >> Ubiquo::Config.add(:a)
  #  >> Ubiquo::Config.get(:a)
  #  => nil
  #  >> Ubiquo::Config.set_default(:a, 1)
  #  >> Ubiquo::Config.get(:a)
  #  => 1
  #
  #Can ge used with a block.
  #  >> Ubiquo::Config.add(:a)
  #  >> Ubiquo::Config.add(:b)
  #  >> Ubiquo::Config.add(:c)
  #  >> Ubiquo::Config.set_default do |configurator|
  #       configurator.a = 1
  #       configurator.b = 2
  #       configurator.c = 3
  #     end
  #  >> Ubiquo::Config.get(:c)
  #  => 3

  def self.set_default(name = nil, default_value = nil, &block)
    if block_given?
      block_assignment(&block).each do |name, default_value|
        set_default_value(name, default_value)
      end
    else
      raise InvalidOptionName if !check_valid_name(name)
      raise OptionNotFound if !self.option_exists?(name)
      name = name.to_sym
      configuration[self.current_context][:default_values][name] = default_value
     end
  end

  #Set a value to an existent option of the current context( default :BASE).
  #Example:
  #  >> Ubiquo::Config.add(:a)
  #  >> Ubiquo::Config.get(:a)
  #  => nil
  #  >> Ubiquo::Config.set(:a, 1)
  #  >> Ubiquo::Config.get(:a)
  #  => 1
  #
  #Can ge used with a block.
  #  >> Ubiquo::Config.add(:a)
  #  >> Ubiquo::Config.add(:b)
  #  >> Ubiquo::Config.add(:c)
  #  >> Ubiquo::Config.set do |configurator|
  #       configurator.a = 1
  #       configurator.b = 2
  #       configurator.c = 3
  #     end
  #  >> Ubiquo::Config.get(:c)
  #  => 3

  def self.set(name = nil, value = nil, &block)
    if block_given?
      block_assignment(&block).each do |name, default_value|
        set(name, default_value)
      end
    else
      raise InvalidOptionName if !check_valid_name(name)
      raise OptionNotFound if !self.option_exists?(name)
      name = name.to_sym
      configuration[self.current_context][:values][name] = value
    end
  end

  #Get the value of a given option name in the current context(default :BASE). Will return the standard value if setted or default value. If no default value or standard value defined, raises Ubiquo::Config::ValueNeverSetted
  #Example:
  #  >> Ubiquo::Config.add(:a, 1)
  #  >> Ubiquo::Config.get(:a)
  #  => 1
  #  >> Ubiquo::Config.set(:a, 2)
  #  >> Ubiquo::Config.get(:a)
  #  => 2

  def self.get(name)
    raise InvalidOptionName if !check_valid_name(name)
    raise OptionNotFound.new(name) if !self.option_exists?(name)
    name = name.to_sym

    if configuration[self.current_context][:values].include?(name)
      configuration[self.current_context][:values][name]
    elsif configuration[self.current_context][:default_values].include?(name)
      configuration[self.current_context][:default_values][name]
    elsif configuration[self.current_context][:inherited_values].include?(name)
      configuration[self.current_context][:inherited_values][name].call
    else
      raise ValueNeverSetted
    end
  end

  def self.call(name, run_in, options = {})
    case option = self.get(name)
    when Proc
      method_name = "_ubi_config_call_#{Time.now.to_f*10000}"
      while(run_in.respond_to?(method_name))
        method_name = "_" + method_name
      end
      run_in.class.send(:define_method, method_name, &option)
      run_in.send(method_name, options).tap do
        run_in.class.send(:remove_method, method_name)
      end
    when String, Symbol
      run_in.send option, options
    end
  end

  #Creates a context. Contexts contains an independent structure which stores options.
  #Example:
  #  >> Ubiquo::Config.add(:a, 1)  # Context :BASE
  #  >> Ubiquo::Config.create_context(:context)
  #  >> Ubiquo::Config.context(:context).add(:a, 2)
  #  >> Ubiquo::Config.context(:context).get(:a)
  #  => 2

  def self.create_context(name)
    raise InvalidContextName if !check_valid_context_name(name)
    raise AlreadyExistingContext if configuration.include?(name)
    name = name.to_sym
    configuration.merge!(self.new_context_options(name))
    true
  end

  #Allow to work in the desired context. Can be used inline or as block.
  #Example:
  #  >> Ubiquo::Config.add(:a, 1)  # Context :BASE
  #  >> Ubiquo::Config.create_context(:context)
  #  >> Ubiquo::Config.context(:context).add(:a, 2)
  #  >> Ubiquo::Config.context(:context).get(:a)
  #  => 2
  #
  #  >> value = nil
  #  => nil
  #  >> Ubiquo::Config.context(:context) do |config|
  #       config.set(:a), 3
  #       value = config.get(:a)
  #     end
  #  >> value
  #  => 3
  def self.context(name, &block)
    raise ContextNotFound if !self.context_exists?(name)
    if block_given?
      returning_value = nil
      begin
        old_context, @context = @context, name.to_sym
        returning_value = block.call(self)
      rescue
        raise $!
      ensure
        @context = old_context
      end
      returning_value
    else
     # raise BlockNeeded
      myself = self
      Proxy.send(:define_method, :my_method_missing){ |method, args, block|
        return_value = nil
        myself.context(name){|contexted|
          return_value = contexted.send(method, *args, &block)
        }
        return_value
      }
      Proxy.new
    end
  end

  def self.option_exists?(name)
    configuration[self.current_context][:allowed_options].include?(name)
  end

  #Returns true only if the context exists

  def self.context_exists?(name)
    configuration.include?(name)
  end

  private

  def self.check_valid_name(name)
    case(name)
    when Symbol, String
      !name.to_s.empty?
    else
      false
    end
  end


  def self.check_valid_context_name(name)
    self.check_valid_name(name)
  end

  def self.block_assignment(&block)
    options = OpenStruct.new()
    block.call(options)
    options.instance_variable_get("@table")
  end

  def self.current_context
    @context ||= :BASE
    @context.to_sym
  end

  def self.new_context_options(name = self.current_context)
    {
      name.to_sym => {
        :values => {},
        :default_values => {},
        :allowed_options => [],
        :inherited_values => {}
      }
    }
  end

  self.configuration ||= self.new_context_options

  class InvalidOptionName < StandardError; end
  class InvalidContextName < StandardError; end
  class InvalidValue < StandardError; end
  class AlreadyExistingOption < StandardError; end
  class AlreadyExistingContext < StandardError; end
  class ContextNotFound < StandardError; end
  class OptionNotFound < StandardError; end
  class ValueNeverSetted < StandardError; end
  class BlockNeeded < StandardError; end

  class Proxy
    def method_missing(method, *args, &block)
        my_method_missing(method, args, block)
    end
  end
end
