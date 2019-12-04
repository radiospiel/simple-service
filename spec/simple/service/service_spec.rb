require "spec_helper"

describe "Simple::Service" do
  context "when running against a NoService module" do
    let(:service) { NoServiceModule }

    describe ".service?" do
      it "returns false on a NoService module" do
        expect(Simple::Service.service?(service)).to eq(false)
      end
    end

    describe ".actions" do
      it "raises an argument error" do
        expect { Simple::Service.actions(service) }.to raise_error(ArgumentError)
      end
    end

    describe ".action" do
      it "raises an argument error" do
        expect { Simple::Service.action(service, :service1) }.to raise_error(ArgumentError)
      end
    end

    describe ".invoke3" do
      it "raises an argument error" do
        ::Simple::Service.with_context do
          expect { Simple::Service.invoke3(service, :service1, {}, {}, context: nil) }.to raise_error(::ArgumentError)
        end
      end
    end
  end

  # running against a proper service module
  let(:service) { SpecService }

  describe ".service?" do
    it "returns true" do
      expect(Simple::Service.service?(service)).to eq(true)
    end
  end

  describe ".actions" do
    it "returns a Hash of actions on a Service module" do
      actions = Simple::Service.actions(service)
      expect(actions).to be_a(Hash)
      expect(actions.keys).to contain_exactly(:service1, :service2, :service3)
    end
  end

  describe ".action" do
    context "with an existing name" do
      it "returns a Action object" do
        action = Simple::Service.action(service, :service1)
        expect(action.service).to eq(service)
        expect(action.name).to eq(:service1)
      end
    end

    describe "Simple::Service::NoSuchAction" do
      it "does not inherit from Simple::Service::ArgumentError" do
        expect(Simple::Service::NoSuchAction < Simple::Service::ArgumentError).to be_falsey
      end

      it "inherits from ArgumentError" do
        expect(Simple::Service::NoSuchAction < ::ArgumentError).to eq true
      end
    end

    context "with an unknown name" do
      it "raises a NoSuchAction error" do
        expect do
          Simple::Service.action(service, :no_such_service)
        end.to raise_error(Simple::Service::NoSuchAction, /No such action :no_such_service/)
      end
    end
  end

  describe '.invoke3' do
    def invoke3
      Simple::Service.invoke3(service, :service1, "my_a", "my_b", d: "my_d")
    end

    context "when context is not set" do
      it "raises a ContextMissingError" do
        action = Simple::Service.actions(service)[:service1]
        expect(action).not_to receive(:invoke)

        expect do
          invoke3
        end.to raise_error(::Simple::Service::ContextMissingError)
      end
    end

    context "when context is set" do
      it "calls Action#invoke with the right arguments" do
        action = Simple::Service.actions(service)[:service1]
        expect(action).to receive(:invoke).with(args: ["my_a", "my_b"], flags: { "d" => "my_d" })

        ::Simple::Service.with_context do
          invoke3
        end
      end
    end
  end

  describe ".invoke" do
    context "with a args array" do
      def invoke
        Simple::Service.invoke(service, :service1, args: ["my_a", "my_b"], flags: { "d" => "my_d" })
      end

      context "when context is not set" do
        it "raises a ContextMissingError" do
          action = Simple::Service.actions(service)[:service1]
          expect(action).not_to receive(:invoke)

          expect do
            invoke
          end.to raise_error(::Simple::Service::ContextMissingError)
        end
      end

      context "when context is set" do
        it "calls Action#invoke with the right arguments" do
          action = Simple::Service.actions(service)[:service1]
          expect(action).to receive(:invoke).with(args: ["my_a", "my_b"], flags: { "d" => "my_d" }).and_call_original

          ::Simple::Service.with_context do
            invoke
          end
        end
      end
    end
  end

  describe "documentation example" do
    def invoke(*args, **flags)
      Simple::Service.invoke(SpecTestService, :foo, *args, **flags)
    end

    def invoke3(*args, **flags)
      Simple::Service.invoke3(SpecTestService, :foo, *args, **flags)
    end

    it "calls Action#invoke with the right arguments" do
      expected = ["bar-value", "baz-value"]
      ::Simple::Service.with_context do
      expect(invoke3("bar-value", baz: "baz-value")).to eq(expected)
      expect(invoke3(bar: "bar-value", baz: "baz-value")).to eq(expected)
      expect(invoke(args: ["bar-value"], flags: { "baz" => "baz-value" })).to eq(expected)
      expect(invoke(args: { "bar" => "bar-value", "baz" => "baz-value" })).to eq(expected)
    end
    end
  end
end
