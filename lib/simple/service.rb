module Simple::Service
  class ArgumentError < ::ArgumentError
  end
end

require_relative "service/action"
require_relative "service/context"

# The Simple::Service module.
#
# To mark a target module as a service module one must include the
# Simple::Service module into the target module.
#
# This serves as a marker that this module is actually intended
# to be used as a service.
module Simple::Service
  def self.included(klass)
    klass.extend ClassMethods
  end

  # Returns the current context.
  def self.context
    Thread.current[:"Simple::Service.context"]
  end

  # yields a block with a given context, and restores the previous context
  # object afterwards.
  def self.with_context(ctx, &block)
    expect! ctx => [Simple::Service::Context, nil]
    _ = block

    old_ctx = Thread.current[:"Simple::Service.context"]
    Thread.current[:"Simple::Service.context"] = ctx
    yield
  ensure
    Thread.current[:"Simple::Service.context"] = old_ctx
  end

  def self.action(service, name)
    actions = self.actions(service)
    actions[name] || begin
      action_names = actions.keys.sort
      informal = "service #{service} has these actions: #{action_names.map(&:inspect).join(", ")}"
      raise "No such action #{name.inspect}; #{informal}"
    end
  end

  def self.service?(service)
    service.is_a?(Module) && service.include?(self)
  end

  def self.actions(service)
    raise ArgumentError, "service must be a #{self}" unless service?(service)

    service.__simple_service_actions__
  end

  def self.invoke(service, name, arguments, params, context: nil)
    with_context(context) do
      action(service, name).invoke(arguments, params)
    end
  end

  module ClassMethods
    # returns a Hash of actions provided by the service module.
    def __simple_service_actions__ # :nodoc:
      @__simple_service_actions__ ||= Action.enumerate(service: self)
    end
  end

  # Resolves a service by name. Returns nil if the name does not refer to a service,
  # or the service module otherwise.
  def self.resolve(str)
    return unless str =~ /^[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*$/

    service = resolve_constant(str)

    return unless service.is_a?(Module)
    return unless service.include?(::Simple::Service)

    service
  end

  def self.resolve_constant(str)
    const_get(str)
  rescue NameError
    nil
  end
end
