require "simple/service"

module Simple::Workflow
  module HelperMethods
    def invoke(*args, **kwargs)
      Simple::Workflow.invoke(self, *args, **kwargs)
    end
  end

  module ModuleMethods
    def register_workflow(mod)
      expect! mod => Module

      mod.extend HelperMethods
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
      expect! workflow => [Module, String]

      workflow_module = lookup_workflow!(workflow)

      # We will reload workflow modules only once per invocation.
      if Simple::Workflow.reload_on_invocation?
        Simple::Service.context.reload!(workflow_module)
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
