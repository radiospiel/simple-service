require "simple-immutable"

module Simple::Service
  module CurrentContext
    # Returns the current context.
    #
    # This method never returns nil - it raises a ContextMissingError exception if
    # the context was not initialized (via <tt>Simple::Service.with_context</tt>).
    def context
      Thread.current[:"Simple::Service.context"] || raise(ContextMissingError)
    end

    # Returns a logger
    #
    # Returns a logger if a context is set and contains a logger.
    def logger
      current_context = Thread.current[:"Simple::Service.context"]
      current_context&.logger?
    end

    # yields a block with a given context, and restores the previous context
    # object afterwards.
    def with_context(ctx = nil, &block)
      old_ctx = Thread.current[:"Simple::Service.context"]

      if old_ctx && ctx.nil?
        block.call
      else
        begin
          Thread.current[:"Simple::Service.context"] = Context.new(ctx, old_ctx)

          block.call
        ensure
          Thread.current[:"Simple::Service.context"] = old_ctx
        end
      end
    end
  end

  extend CurrentContext
end
