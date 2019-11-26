# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity

module Simple::Service
  class Action
  end
end

require_relative "./action/comment"
require_relative "./action/parameter"

module Simple::Service
  class Action
    ArgumentError = ::Simple::Service::ArgumentError

    IDENTIFIER_PATTERN = "[a-z][a-z0-9_]*"
    IDENTIFIER_REGEXP = Regexp.compile("\\A#{IDENTIFIER_PATTERN}\\z")

    # determines all services provided by the +service+ service module.
    def self.enumerate(service:) # :nodoc:
      service.public_instance_methods(false)
             .grep(IDENTIFIER_REGEXP)
             .each_with_object({}) { |name, hsh| hsh[name] = Action.new(service, name) }
    end

    attr_reader :service
    attr_reader :name

    # returns an Array of Parameter structures.
    def parameters
      @parameters ||= Parameter.reflect_on_method(service: service, name: name)
    end

    def initialize(service, name)
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
    def invoke(args, options)
      args   ||= {}
      options ||= {}

      # convert Array arguments into a Hash of named arguments. This is strictly
      # necessary to be able to apply default value-based type conversions. (On
      # the downside this also means we convert an array to a hash and then back
      # into an array. This, however, should only be an issue for CLI based action
      # invocations, because any other use case (that I can think of) should allow
      # us to provide arguments as a Hash. 
      if args.is_a?(Array)
        args = convert_argument_array_to_hash(args)
      end

      # [TODO] Type conversion according to default values.
      args_ary = build_method_arguments(args, options)

      service_instance = Object.new
      service_instance.extend service
      service_instance.public_send(@name, *args_ary)
    end

    private

    module IndifferentHashEx
      def self.fetch(hsh, name)
        missing_key!(name) unless hsh

        hsh.fetch(name.to_sym) do
          hsh.fetch(name.to_s) do
            missing_key!(name)
          end
        end
      end

      def self.key?(hsh, name)
        return false unless hsh

        hsh.key?(name.to_sym) || hsh.key?(name.to_s)
      end

      def self.missing_key!(name)
        raise ArgumentError, "Missing argument in arguments hash: #{name}"
      end
    end

    I = IndifferentHashEx

    # returns an array of arguments suitable to be sent to the action method.
    def build_method_arguments(args_hsh, params_hsh)
      args = []
      keyword_args = {}

      parameters.each do |parameter|
        if parameter.keyword?
          if I.key?(params_hsh, parameter.name)
            keyword_args[parameter.name] = I.fetch(params_hsh, parameter.name)
          end
        else
          if parameter.variadic?
            if I.key?(args_hsh, parameter.name)
              args.concat(Array(I.fetch(args_hsh, parameter.name)))
            end
          else
            if !parameter.optional? || I.key?(args_hsh, parameter.name)
              args << I.fetch(args_hsh, parameter.name)
            end
          end
        end
      end

      unless keyword_args.empty?
        args << keyword_args
      end

      args
    end

    def convert_argument_array_to_hash(ary)
      # enumerate all of the action's anonymous arguments, trying to match them
      # against the values in +ary+. If afterwards any arguments are still left
      # in +ary+ they will be assigned to the variadic arguments array, which
      # - if a variadic parameter is defined in this action - will be added to
      # the hash as well.
      hsh = {}
      variadic_parameter_name = nil

      parameters.each do |parameter|
        next if parameter.keyword?
        parameter_name = parameter.name

        if parameter.variadic?
          variadic_parameter_name = parameter_name
          next
        end

        if ary.empty? && !parameter.optional?
          raise ::Simple::Service::ArgumentError, "Missing #{parameter_name} parameter"
        end

        next if ary.empty?

        hsh[parameter_name] = ary.shift
      end

      # Any arguments are left? Set variadic parameter, if defined, raise an error otherwise.
      unless ary.empty?
        unless variadic_parameter_name
          raise ::Simple::Service::ArgumentError, "Extra parameters: #{ary.map(&:inspect).join(", ")}"
        end

        hsh[variadic_parameter_name] = ary
      end

      hsh
    end

    def full_name
      "#{service}##{name}"
    end

    def to_s
      full_name
    end
  end
end
