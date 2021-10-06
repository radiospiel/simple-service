require "spec_helper"

describe Simple::Workflow::CurrentContext do
  describe ".with_context" do
    it "merges the current context for the duration of the block" do
      block_called = false

      Simple::Workflow.with_context(a: "a", foo: "bar") do
        expect(Simple::Workflow.current_context.a).to eq("a")
        expect(Simple::Workflow.current_context.foo).to eq("bar")

        # layering
        Simple::Workflow.with_context() do
          expect(Simple::Workflow.current_context.foo).to eq("bar")

          expect(Simple::Workflow.current_context.unknown?).to be_nil
          expect {
            Simple::Workflow.current_context.unknown
          }.to raise_error(NameError)
        end

        # overwrite value
        Simple::Workflow.with_context(a: "b") do
          expect(Simple::Workflow.current_context.a).to eq("b")
          block_called = true
        end

        # overwrite value w/nil
        Simple::Workflow.with_context(a: nil) do
          expect(Simple::Workflow.current_context.a).to be_nil
          Simple::Workflow.with_context(a: "c") do
            expect(Simple::Workflow.current_context.a).to eq("c")
          end
        end
        expect(Simple::Workflow.current_context.a).to eq("a")
      end

      expect(block_called).to eq(true)
    end
  end
end
