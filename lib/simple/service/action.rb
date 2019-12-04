module Simple::Service
  class Action
  end
end

require_relative "./action/comment"
require_relative "./action/parameter"

module Simple::Service
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
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

    # invokes an action with a given +name+ in a service with a Hash of arguments.
    #
    # You cannot call this method if the context is not set.
    def invoke(args:, flags:)
      args = convert_argument_array_to_hash(args) if args.is_a?(Array)

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
      @positional_names ||= parameters.select(&:positional?).map(&:name).map(&:to_s)
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

      # +ary* might contain more, less, or the exact number of positional
      # arguments. If the number is less, we return a hash with only whart
      # exists in ary - the action might define default values after all.
      #
      # If it contains more the action better supports a variadic parameter;
      # we otherwise raise a ExtraArguments exception.
      case ary.length <=> positional_names.length
      when 1  # i.e. ary.length > positional_names.length
        extra_arguments = ary[positional_names.length..-1]
        ary = ary[0..positional_names.length]

        if !extra_arguments.empty? && !variadic_parameter
          raise ::Simple::Service::ExtraArguments.new(self, extra_arguments)
        end

        existing_positional_names = positional_names
      when 0  # i.e. ary.length == positional_names.length
        existing_positional_names = positional_names
      when -1 # i.e. ary.length < positional_names.length
        existing_positional_names = positional_names[0, ary.length]
      end

      # Build a hash with the existing_positional_names and the values from the array.
      hsh = Hash[existing_positional_names.zip(ary)]

      # Add the variadic_parameter, if any.
      hsh[variadic_parameter.name] = extra_arguments if variadic_parameter

      hsh
    end
  end
end
