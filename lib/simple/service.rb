module Simple # :nodoc:
end

require "expectation"

require_relative "service/errors"
require_relative "service/action"
require_relative "service/context"
require_relative "service/version"

# The Simple::Service module.
#
# To mark a target module as a service module one must include the
# Simple::Service module into the target module.
#
# This serves as a marker that this module is actually intended
# to be used as a service.
module Simple::Service
  def self.included(klass) # :nodoc:
    klass.extend ClassMethods
  end

  # returns true if the passed in object is a service module.
  def self.service?(service)
    service.is_a?(Module) && service.include?(self)
  end

  def self.verify_service!(service) # :nodoc:
    raise ::ArgumentError, "#{service.inspect} must be a Simple::Service, but is not even a Module" unless service.is_a?(Module)
    raise ::ArgumentError, "#{service.inspect} must be a Simple::Service, did you 'include Simple::Service'" unless service?(service)
  end

  # returns a Hash with all actions in the +service+ module
  def self.actions(service)
    verify_service!(service)

    service.__simple_service_actions__
  end

  # returns the action with the given name.
  def self.action(service, name)
    actions = self.actions(service)
    actions[name] || begin
      raise ::Simple::Service::NoSuchAction.new(service, name)
    end
  end

  # invokes an action with a given +name+ in a service with +arguments+ and +params+.
  #
  # You cannot call this method if the context is not set.
  #
  # When calling #invoke using positional arguments they will be matched against
  # positional arguments of the invoked method - but they will not be matched
  # against named arguments.
  #
  # When there are not enough positional arguments to match the number of required
  # positional arguments of the method we raise an ArgumentError.
  #
  # When there are more positional arguments provided than the number accepted
  # by the method we raise an ArgumentError.
  #
  # Entries in the named_args Hash that are not defined in the action itself are ignored.
  def self.invoke(service, name, *args, **named_args)
    raise ContextMissingError, "Need to set context before calling ::Simple::Service.invoke" unless context

    action(service, name).invoke(*args, **named_args)
  end

  # invokes an action with a given +name+ in a service with a Hash of arguments.
  #
  # You cannot call this method if the context is not set.
  def self.invoke2(service, name, **args)
    args.each { |key, _| expect! key => Symbol }
    raise ContextMissingError, "Need to set context before calling ::Simple::Service.invoke" unless context

    action(service, name).invoke2(**args)
  end

  module ClassMethods # :nodoc:
    # returns a Hash of actions provided by the service module.
    def __simple_service_actions__
      @__simple_service_actions__ ||= Action.enumerate(service: self)
    end
  end

  # # Resolves a service by name. Returns nil if the name does not refer to a service,
  # # or the service module otherwise.
  # def self.resolve(str)
  #   return unless str =~ /^[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*$/
  #
  #   service = resolve_constant(str)
  #
  #   return unless service.is_a?(Module)
  #   return unless service.include?(::Simple::Service)
  #
  #   service
  # end
  #
  # def self.resolve_constant(str)
  #   const_get(str)
  # rescue NameError
  #   nil
  # end
end
