module Simple::Service
  # Returns the current context.
  def self.context
    Thread.current[:"Simple::Service.context"] || raise(ContextMissingError)
  end

  # yields a block with a given context, and restores the previous context
  # object afterwards.
  def self.with_context(ctx = nil, &block)
    old_ctx = Thread.current[:"Simple::Service.context"]

    Thread.current[:"Simple::Service.context"] = Context.new(ctx, old_ctx)

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

      hsh = hsh ? hsh.transform_keys(&:to_s) : {}

      @previous_context = previous_context
      super(hsh)
    end

    IDENTIFIER = "[a-z][a-z0-9_]*" # @private

    def method_missing(sym, *args, &block)
      raise ArgumentError, "#{self.class.name}##{sym}: Block given" if block
      raise ArgumentError, "#{self.class.name}##{sym}: Extra args" unless args.empty?

      if sym !~ /\A(#{IDENTIFIER})(\?)?\z/
        raise ArgumentError, "#{self.class.name}: Invalid context key '#{sym}'"
      end

      @hsh.fetch($1) do
        # $1 is not defined here..

        # This is an overlayed context?
        if @previous_context
          @previous_context.send(sym)
        elsif $2
          # +sym+ ends in question mark, i.e. we return +nil+ on missing entries.
          nil
        else
          super
        end
      end
    end

    def respond_to_missing?(sym, include_private = false)
      is_defined_here = if sym =~ /\A(#{IDENTIFIER})(\?)\z/
                          $2 || @hsh.key?(sym)
                        else
                          super
                        end

      return true if is_defined_here
      return false unless @previous_context

      @previous_context.respond_to_missing?(sym, include_private)
    end
  end
end
