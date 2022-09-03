module Simple # @private
end

module Simple::Service # @private
end

require "expectation"
require "logger"

require_relative "service/errors"
require_relative "service/action"
require_relative "service/version"

# <b>The Simple::Service interface</b>
#
# This module implements the main API of the Simple::Service ruby gem.
#
# 1. <em>Marking a service module:</em> To turn a target module as a service module one must include <tt>Simple::Service</tt>
#    into the target. This serves as a marker that this module is actually intended
#    to provide one or more services. Example:
#
#     module GodMode
#       include Simple::Service
#
#       # Build a universe.
#       #
#       # This comment will become part of the full description of the
#       # "build_universe" service
#       def build_universe(name, c: , pi: 3.14, e: 2.781)
#         # at this point I realize that *I* am not God.
#
#         42 # Best try approach
#       end
#     end
#
# 2. <em>Discover services:</em> To discover services in a service module use the #actions method. This returns a Hash
#    of actions.
#
#     Simple::Service.actions(GodMode)
#     => {:build_universe=>#<Simple::Service::Action...>, ...}
#
# TODO: why a Hash? It feels much better if Simple::Service.actions returns an array of names.
#
#
# 3. <em>Invoke a service:</em> run <tt>Simple::Service.invoke3</tt> or <tt>Simple::Service.invoke</tt>.
#
#     Simple::Service.invoke3(GodMode, :build_universe, "TestWorld", c: 1e9)
#     => 42
#
module Simple::Service
  module ServiceExpectations
    def expect!(*args, &block)
      Expectation.expect!(*args, &block)
    rescue ::Expectation::Error => e
      raise ArgumentError, e.to_s
    end
  end

  def self.included(klass) # @private
    klass.extend ClassMethods
    klass.include ServiceExpectations
  end

  # Raises an error if the passed in object is not a Simple::Service
  def self.verify_service!(service) # @private
    expect! service => Module

    # rubocop:disable Style/GuardClause
    unless service.include?(::Simple::Service)
      raise ::ArgumentError,
            "#{service.name} is not a Simple::Service, did you 'include Simple::Service'"
    end
    # rubocop:enable Style/GuardClause
  end

  # returns a Hash with all actions in the +service+ module
  def self.actions(service)
    verify_service!(service)

    service.__simple_service_actions__
  end

  # returns the action with the given name.
  def self.action(service, name)
    expect! name => Symbol

    actions = self.actions(service)
    actions[name] || begin
      raise ::Simple::Service::NoSuchActionError.new(service, name)
    end
  end

  # invokes an action with a given +name+ in a service with +args+ and +flags+.
  #
  # This is a helper method which one can use to easily call an action from
  # ruby source code.
  #
  # As the main purpose of this module is to call services with outside data,
  # the +.invoke+ action is usually preferred.
  def self.invoke3(service, name, *args, **flags)
    # The following checks if flags is empty. This might be intentional, but might also mean that
    # the caller is sending in kwargs as last arguments of the args array.
    #
    # This is supported in 2.7.*, but no longer works with ruby 3.
    if flags.empty? && args.last.is_a?(Hash)
      flags = args.pop
    end

    flags = flags.transform_keys(&:to_s)
    invoke service, name, args: args, flags: flags
  end

  # invokes an action with a given +name+.
  #
  # This is the general form of invoking a service. It accepts the following
  # arguments:
  #
  # - args: an Array of positional arguments OR a Hash of named arguments.
  # - flags: a Hash of flags.
  #
  # Note that the keys in both the +flags+ and the +args+ Hash must be strings.
  #
  # The service is being called with a parameters built out of those like this:
  #
  # - The service's positional arguments are being built from the +args+ array
  #   parameter or from the +named_args+ hash parameter.
  # - The service's keyword arguments are being built from the +named_args+
  #   and +flags+ arguments.
  #
  # In other words:
  #
  # 1. You cannot set both +args+ and +named_args+ at the same time.
  # 2. The +flags+ arguments are only being used to determine the
  #    service's keyword parameters.
  #
  # So, if the service X implements an action "def foo(bar, baz:)", the following would
  # all invoke that service:
  #
  # - +Service.invoke3(X, :foo, "bar-value", baz: "baz-value")+, or
  # - +Service.invoke3(X, :foo, bar: "bar-value", baz: "baz-value")+, or
  # - +Service.invoke(X, :foo, args: ["bar-value"], flags: { "baz" => "baz-value" })+, or
  # - +Service.invoke(X, :foo, args: { "bar" => "bar-value", "baz" => "baz-value" })+.
  #
  # (see spec/service_spec.rb)
  #
  # When there are not enough positional arguments to match the number of required
  # positional arguments of the method we raise an ArgumentError.
  #
  # When there are more positional arguments provided than the number accepted
  # by the method we raise an ArgumentError.
  #
  # Entries in the +named_args+ Hash that are not defined in the action itself are ignored.
  def self.invoke(service, name, args: {}, flags: {})
    expect! args => [Hash, Array], flags: Hash
    args.each_key { |key| expect! key => String } if args.is_a?(Hash)
    flags.each_key { |key| expect! key => String }

    action(service, name).invoke(args: args, flags: flags)
  end

  module ClassMethods # @private
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
