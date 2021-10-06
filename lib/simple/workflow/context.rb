require "simple/immutable"

module Simple::Workflow
  # A context object
  #
  # Each service executes with a current context. The system manages a stack of
  # contexts; whenever a service execution is done the current context is reverted
  # to its previous value.
  #
  # A context object can store a large number of values; the only way to set or
  # access a value is via getters and setters. These are implemented via
  # +method_missing(..)+.
  #
  # Also, once a value is set in the context it is not possible to change or
  # unset it.
  class Context < Simple::Immutable
    SELF = self

    # returns a new Context object.
    #
    # Parameters:
    #
    # - hsh (Hash or nil): sets values for this context
    # - previous_context (Context or nil): if +previous_context+ is provided,
    #   values that are not defined in the \a +hsh+ argument are read from the
    #   +previous_context+ instead (or the previous context's +previous_context+,
    #   etc.)
    def initialize(hsh, previous_context = nil)
      expect! hsh => [Hash, nil]
      expect! previous_context => [SELF, nil]

      @previous_context = previous_context
      super(hsh || {})
    end

    def reload!(a_module)
      if @previous_context
        @previous_context.reload!(a_module)
        return a_module
      end

      @reloaded_modules ||= []
      return if @reloaded_modules.include?(a_module)

      ::Simple::Workflow::Reloader.reload(a_module)
      @reloaded_modules << a_module
      a_module
    end

    def fetch_attribute!(sym, raise_when_missing:)
      unless @previous_context
        return super(sym, raise_when_missing: raise_when_missing)
      end

      first_error = nil

      # check this context first. We catch any NameError, to be able to look up
      # the attribute also in the previous_context.
      begin
        return super(sym, raise_when_missing: true)
      rescue NameError => e
        first_error = e
      end

      # check previous_context
      begin
        return @previous_context.fetch_attribute!(sym, raise_when_missing: raise_when_missing)
      rescue NameError
        :nop
      end

      # Not in +self+, not in +previous_context+, and +raise_when_missing+ is true:
      raise(first_error)
    end

    # def inspect
    #   if @previous_context
    #     "#{object_id} [" + @hsh.keys.map(&:inspect).join(", ") + "; #{@previous_context.inspect}]"
    #   else
    #     "#{object_id} [" + @hsh.keys.map(&:inspect).join(", ") + "]"
    #   end
    # end

    private

    IDENTIFIER = "[a-z_][a-z0-9_]*" # @private

    def method_missing(sym, *args, &block)
      raise ArgumentError, "#{self.class.name}##{sym}: Block given" if block
      raise ArgumentError, "#{self.class.name}##{sym}: Extra args #{args.inspect}" unless args.empty?

      if sym !~ /\A(#{IDENTIFIER})(\?)?\z/
        raise ArgumentError, "#{self.class.name}: Invalid context key '#{sym}'"
      end

      # rubocop:disable Lint/OutOfRangeRegexpRef
      fetch_attribute!($1, raise_when_missing: $2.nil?)
      # rubocop:enable Lint/OutOfRangeRegexpRef
    end

    def respond_to_missing?(sym, include_private = false)
      super || @previous_context&.respond_to_missing?(sym, include_private)
    end
  end
end
