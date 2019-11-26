require_relative "method_reflection"

class ::Simple::Service::Action::Parameter
  def self.reflect_on_method(service:, name:)
    reflected_parameters = ::Simple::Service::Action::MethodReflection.parameters(service, name)
    @parameters = reflected_parameters.map { |ary| new(*ary) }
  end

  def keyword?
    [:key, :keyreq].include? @kind
  end

  def anonymous?
    [:req, :opt].include? @kind
  end

  def required?
    [:req, :keyreq].include? @kind
  end

  def variadic?
    @kind == :rest
  end

  def optional?
    !required?
  end

  attr_reader :name
  attr_reader :kind

  # The parameter's default value (if any)
  attr_reader :default_value

  def initialize(kind, name, *default_value)
    # The parameter list matches the values returned from MethodReflection.parameters,
    # which has two or three entries: <tt>kind, name [ . default_value ]</tt>

    expect! kind => [:req, :opt, :keyreq, :key, :rest]
    expect! default_value.length => [0, 1]

    @kind = kind
    @name = name
    @default_value = default_value[0]
  end
end
