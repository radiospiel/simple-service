module Simple::Service
  # Will be raised by ::Simple::Service.action.
  class NoSuchAction < ::ArgumentError
    attr_reader :service, :name

    def initialize(service, name)
      @service, @name = service, name
      super()
    end

    def to_s
      action_names = ::Simple::Service.actions(service).keys.sort
      informal = "service #{service} has these actions: #{action_names.map(&:inspect).join(", ")}"
      "No such action #{name.inspect}; #{informal}"
    end
  end

  class ArgumentError < ::ArgumentError
  end

  class MissingArguments < ArgumentError
    attr_reader :action
    attr_reader :parameters

    def initialize(action, parameters)
      @action, @parameters = action, parameters
      super()
    end

    def to_s
      "#{action}: missing argument(s): #{parameters.map(&:to_s).join(", ")}"
    end
  end

  class ExtraArguments < ArgumentError
    attr_reader :action
    attr_reader :arguments

    def initialize(action, arguments)
      @action, @arguments = action, arguments
      super()
    end

    def to_s
      str = @arguments.map(&:inspect).join(", ")
      "#{action}: extra argument(s) #{str}"
    end
  end

  class ContextMissingError < ::StandardError
    def to_s
      "Simple::Service.context not initialized; remember to call Simple::Service.with_context/1"
    end
  end

  class ContextReadOnlyError < ::StandardError
    def initialize(key)
      super "Cannot overwrite existing context setting #{key.inspect}"
    end
  end
end
