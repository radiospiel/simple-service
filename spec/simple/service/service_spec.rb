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

    describe ".invoke" do
      it "raises an argument error" do
        ::Simple::Service.with_context do
          expect { Simple::Service.invoke(service, :service1, {}, {}, context: nil) }.to raise_error(::ArgumentError)
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

  describe ".invoke" do
    let(:positionals) { { a: "my_a", b: "my_b" } }
    let(:named) { { d: "my_d" } }

    context "when context is not set" do
      it "raises a ContextMissingError" do
        action = Simple::Service.actions(service)[:service1]
        expect(action).not_to receive(:invoke)

        expect do
          Simple::Service.invoke(service, :service1, *positionals, named_args: named)
        end.to raise_error(::Simple::Service::ContextMissingError)
      end
    end

    context "when context is not set" do
      it "properly delegates call to action object" do
        action = Simple::Service.actions(service)[:service1]
        expect(action).to receive(:invoke).with(*positionals, named_args: named)

        ::Simple::Service.with_context do
          Simple::Service.invoke(service, :service1, *positionals, named_args: named)
        end
      end
    end
  end
end
