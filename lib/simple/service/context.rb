module Simple::Service
  # Returns the current context.
  def self.context
    Thread.current[:"Simple::Service.context"]
  end

  # yields a block with a given context, and restores the previous context
  # object afterwards.
  def self.with_context(ctx = nil, &block)
    old_ctx = Thread.current[:"Simple::Service.context"]
    new_ctx = old_ctx ? old_ctx.merge(ctx) : Context.new(ctx)

    Thread.current[:"Simple::Service.context"] = new_ctx

    block.call
  ensure
    Thread.current[:"Simple::Service.context"] = old_ctx
  end
end

module Simple::Service
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
  class Context
    def initialize(hsh = {}) # :nodoc:
      @hsh = hsh
    end

    # returns a new Context object, which merges the values in the +overlay+
    # argument (which must be a Hash or nil) with the values in this context.
    #
    # The overlay is allowed to change values in the current context.
    #
    # It does not change this context.
    def merge(overlay)
      expect! overlay => [Hash, nil]

      overlay ||= {}
      new_context_hsh = @hsh.merge(overlay)
      ::Simple::Service::Context.new(new_context_hsh)
    end

    private

    IDENTIFIER_PATTERN = "[a-z][a-z0-9_]*" # :nodoc:
    IDENTIFIER_REGEXP = Regexp.compile("\\A#{IDENTIFIER_PATTERN}\\z") # :nodoc:
    ASSIGNMENT_REGEXP = Regexp.compile("\\A(#{IDENTIFIER_PATTERN})=\\z") # :nodoc:

    def method_missing(sym, *args, &block)
      raise ArgumentError, "Block given" if block

      if args.count == 0 && sym =~ IDENTIFIER_REGEXP
        self[sym]
      elsif args.count == 1 && sym =~ ASSIGNMENT_REGEXP
        self[$1.to_sym] = args.first
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private = false)
      # :nocov:
      return true if IDENTIFIER_REGEXP.match?(sym)
      return true if ASSIGNMENT_REGEXP.match?(sym)

      super
      # :nocov:
    end

    def [](key)
      @hsh[key]
    end

    def []=(key, value)
      existing_value = @hsh[key]

      unless existing_value.nil? || existing_value == value
        raise ::Simple::Service::ContextReadOnlyError, key
      end

      @hsh[key] = value
    end
  end
end
