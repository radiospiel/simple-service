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

require "simple-immutable"

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
  class Context < Simple::Immutable
    def initialize(hsh)
      expect! hsh => [Hash, nil]

      super(hsh ? hsh.transform_keys(&:to_s) : {})
    end

    # returns a new Context object, which merges the values in the +overlay+
    # argument (which must be a Hash or nil) with the values in this context.
    #
    # The overlay is allowed to change values in the current context.
    #
    # It does not change this context.
    def merge(overlay)
      # This uses the @hsh private instance variable
      expect! overlay => [Hash, nil]

      overlay = (overlay ? overlay.transform_keys(&:to_s) : {})
      new_context_hsh = @hsh.merge(overlay)
      ::Simple::Service::Context.new(new_context_hsh)
    end

    private

    IDENTIFIER = "[a-z][a-z0-9_]*" # @private

    def method_missing(sym, *args, &block)
      raise ArgumentError, "Block given" if block

      if args.count == 0 && sym =~ /\A(#{IDENTIFIER})(\?)?\z/ && $2
        @hsh[$1]
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private = false)
      case sym
      when /\A(#{IDENTIFIER})\z/
        @hsh.key?(sym)
      when /\A(#{IDENTIFIER})\?\z/
        true
      else
        super
      end
    end
  end
end
