module Simple::Service
  class Action
  end
end

require_relative "./action/comment"
require_relative "./action/parameter"
require_relative "./action/indie_hash"

module Simple::Service
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Style/GuardClause
  # rubocop:disable Metrics/ClassLength

  class Action
    IDENTIFIER_PATTERN = "[a-z][a-z0-9_]*" # @private
    IDENTIFIER_REGEXP = Regexp.compile("\\A#{IDENTIFIER_PATTERN}\\z") # @private

    # determines all services provided by the +service+ service module.
    def self.enumerate(service:) # @private
      service.public_instance_methods(false)
             .grep(IDENTIFIER_REGEXP)
             .each_with_object({}) { |name, hsh| hsh[name] = Action.new(service, name) }
    end

    attr_reader :service
    attr_reader :name

    def full_name
      "#{service.name}##{name}"
    end

    def to_s # @private
      full_name
    end

    # returns an Array of Parameter structures.
    def parameters
      @parameters ||= Parameter.reflect_on_method(service: service, name: name)
    end

    def initialize(service, name) # @private
      @service  = service
      @name     = name

      parameters
    end

    def short_description
      comment.short
    end

    def full_description
      comment.full
    end

    private

    # returns a Comment object
    #
    # The comment object is extracted on demand on the first call.
    def comment
      @comment ||= Comment.extract(action: self)
    end

    public

    def source_location
      @service.instance_method(name).source_location
    end

    # build a service_instance and run the action, with arguments constructed from
    # args_hsh and params_hsh.
    def invoke(*args, **named_args)
      # convert Array arguments into a Hash of named arguments. This is strictly
      # necessary to be able to apply default value-based type conversions. (On
      # the downside this also means we convert an array to a hash and then back
      # into an array. This, however, should only be an issue for CLI based action
      # invocations, because any other use case (that I can think of) should allow
      # us to provide arguments as a Hash.
      args = convert_argument_array_to_hash(args)
      named_args = named_args.merge(args)

      invoke2(args: named_args, flags: {})
    end

    # invokes an action with a given +name+ in a service with a Hash of arguments.
    #
    # You cannot call this method if the context is not set.
    def invoke2(args:, flags:)
      # args and flags are being stringified. This is necessary to not allow any
      # unchecked input to DOS this process by just providing always changing
      # key values.
      args = IndieHash.new(args)
      flags = IndieHash.new(flags)

      verify_required_args!(args, flags)

      positionals = build_positional_arguments(args, flags)
      keywords = build_keyword_arguments(args.merge(flags))

      service_instance = Object.new
      service_instance.extend service

      if keywords.empty?
        service_instance.public_send(@name, *positionals)
      else
        # calling this with an empty keywords Hash still raises an ArgumentError
        # if the target method does not accept arguments.
        service_instance.public_send(@name, *positionals, **keywords)
      end
    end

    private

    # returns an error if the keywords hash does not define all required keyword arguments.
    def verify_required_args!(args, flags) # @private
      @required_names ||= parameters.select(&:required?).map(&:name).map(&:to_s)

      missing_parameters = @required_names - args.keys - flags.keys
      return if missing_parameters.empty?

      raise ::Simple::Service::MissingArguments.new(self, missing_parameters)
    end

    # Enumerating all parameters it puts all named parameters into a Hash
    # of keyword arguments.
    def build_keyword_arguments(args)
      @keyword_names ||= parameters.select(&:keyword?).map(&:name).map(&:to_s)

      keys = @keyword_names & args.keys
      values = args.fetch_values(*keys)

      # Note that +keys+ now only contains names of keyword arguments that actually exist.
      # This is therefore not a way to DOS this process.
      Hash[keys.map(&:to_sym).zip(values)]
    end

    def variadic_parameter
      return @variadic_parameter if defined? @variadic_parameter

      @variadic_parameter = parameters.detect(&:variadic?)
    end

    def positional_names
      @positional_names ||= parameters.select(&:positional?).map(&:name)
    end

    # Enumerating all parameters it collects all positional parameters into
    # an Array.
    def build_positional_arguments(args, flags)
      positionals = positional_names.each_with_object([]) do |parameter_name, ary|
        if args.key?(parameter_name)
          ary << args[parameter_name]
        elsif flags.key?(parameter_name)
          ary << flags[parameter_name]
        end
      end

      # A variadic parameter is appended to the positionals array.
      # It is always optional - but if it exists it must be an Array.
      if variadic_parameter
        value = if args.key?(variadic_parameter.name)
                  args[variadic_parameter.name]
                elsif flags.key?(variadic_parameter.name)
                  flags[variadic_parameter.name]
                end

        positionals.concat(value) if value
      end

      positionals
    end

    def convert_argument_array_to_hash(ary)
      expect! ary => Array

      hsh = {}

      if variadic_parameter
        hsh[variadic_parameter.name] = []
      end

      if ary.length > positional_names.length
        extra_arguments = ary[positional_names.length..-1]

        if variadic_parameter
          hsh[variadic_parameter.name] = extra_arguments
        else
          raise ::Simple::Service::ExtraArguments.new(self, extra_arguments)
        end
      end

      ary.zip(positional_names).each do |value, parameter_name|
        hsh[parameter_name] = value
      end

      hsh
    end
  end
end
