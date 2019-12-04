# rubocop:disable Naming/UncommunicativeMethodParamName

module NoServiceModule
end

module SpecService
  include Simple::Service

  # This is service1
  #
  # Service 1 has a full description
  def service1(a, b, c = "speed-of-light", d:, e: 2.781); end

  # This is service2 (no full description)
  def service2
    "service2 return"
  end

  def service3
    nil
  end

  private

  def not_a_service; end
end

module InvokeTestService
  include Simple::Service

  def no_params
    "service2 return"
  end

  def positional_params(a, b, c = "speed-of-light", e = 2.781)
    [a, b, c, e]
  end

  def named_params(a:, b:, c: "speed-of-light", e: 2.781)
    [a, b, c, e]
  end

  def mixed_optional_params(a, b = "default-b", c = "speed-of-light", e: 2.781)
    [a, b, c, e]
  end

  def variadic_params(a, b = "queen bee", *args, e: 2.781)
    [a, b, args, e]
  end
end

module SpecTestService
  include Simple::Service

  def foo(bar, baz:)
    [ bar, baz ]
  end
end
