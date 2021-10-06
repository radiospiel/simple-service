require "simple/service"

require_relative "workflow/context"
require_relative "workflow/current_context"
require_relative "workflow/reloader"

if defined?(RSpec)
  require_relative "workflow/rspec_helper"
end

module Simple::Workflow
  class ContextMissingError < ::StandardError
    def to_s
      "Simple::Workflow.current_context not initialized; remember to call Simple::Workflow.with_context/1"
    end
  end

  module HelperMethods
    def invoke(*args, **kwargs)
      Simple::Workflow.invoke(self, *args, **kwargs)
    end
  end

  module InstanceHelperMethods
    private

    def current_context
      Simple::Workflow.current_context
    end
  end

  module ModuleMethods
    def register_workflow(mod)
      expect! mod => Module

      mod.extend ::Simple::Workflow::HelperMethods
      mod.include ::Simple::Workflow::InstanceHelperMethods
      mod.extend mod
      mod.include Simple::Service
    end

    def reload_on_invocation?
      !!@reload_on_invocation
    end

    def reload_on_invocation!
      @reload_on_invocation = true
    end

    def invoke(workflow, *args, **kwargs)
      # This call to Simple::Workflow.current_context raises a ContextMissingError
      # if the context is not set.
      _ = ::Simple::Workflow.current_context

      expect! workflow => [Module, String]

      workflow_module = lookup_workflow!(workflow)

      # We will reload workflow modules only once per invocation.
      if Simple::Workflow.reload_on_invocation?
        Simple::Workflow.current_context.reload!(workflow_module)
      end

      Simple::Service.invoke(workflow_module, :call, args: args, flags: kwargs.transform_keys(&:to_s))
    end

    private

    def lookup_workflow!(workflow)
      workflow_module = lookup_workflow(workflow)

      verify_workflow! workflow_module

      workflow_module
    end

    def lookup_workflow(workflow)
      case workflow
      when Module
        workflow
      when String
        Object.const_get workflow
      else
        expect! workflow => [Module, String]
      end
    end

    def verify_workflow!(workflow_module)
      return if Simple::Service.actions(workflow_module).key?(:call)

      raise ArgumentError, "#{workflow_module.name} is not a Simple::Workflow"
    end
  end

  extend ModuleMethods
end
