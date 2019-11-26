require "spec_helper"

describe Simple::Service do
  describe ".with_context" do
    it "merges the current context for the duration of the block" do
      block_called = false

      Simple::Service.with_context(a: "a") do
        expect(Simple::Service.context.a).to eq("a")

        # overwrite value
        Simple::Service.with_context(a: "b") do
          expect(Simple::Service.context.a).to eq("b")
          block_called = true
        end

        # overwrite value w/nil
        Simple::Service.with_context(a: nil) do
          expect(Simple::Service.context.a).to be_nil
          Simple::Service.context.a = "c"
          expect(Simple::Service.context.a).to eq("c")
        end
        expect(Simple::Service.context.a).to eq("a")
      end

      expect(block_called).to eq(true)
    end
  end
end

describe Simple::Service::Context do
  let(:context) { Simple::Service::Context.new }

  before do
    context.one = 1
  end

  describe "invalid identifier" do
    it "raises an error" do
      expect { context.one! }.to raise_error(NoMethodError)
    end
  end

  describe "context reading" do
    it "returns a value if set" do
      expect(context.one).to eq(1)
    end

    it "returns nil if not set" do
      expect(context.two).to be_nil
    end
  end

  describe "context writing" do
    it "sets a value if it does not exist yet" do
      context.two = 2
      expect(context.two).to eq(2)
    end

    it "raises a ReadOnly error if the value exists and is not equal" do
      expect { context.one = 2 }.to raise_error(::Simple::Service::ContextReadOnlyError)
    end

    it "sets the value if it exists and is equal" do
      context.one = 1
      expect(context.one).to eq(1)
    end
  end
end
