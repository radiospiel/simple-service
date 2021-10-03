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
          Simple::Service.with_context(a: "c") do
            expect(Simple::Service.context.a).to eq("c")
          end
        end
        expect(Simple::Service.context.a).to eq("a")
      end

      expect(block_called).to eq(true)
    end
  end
end

describe Simple::Service::Context do
  RSpec.shared_examples "context requesting" do
    it "inherits from Simple::Immutable" do
      expect(context).to be_a(Simple::Immutable)
    end

    describe "invalid identifier" do
      it "raises an error" do
        expect { context.one! }.to raise_error(NoMethodError)
        expect { context.oneTwoThree }.to raise_error(NoMethodError)
      end
    end

    describe "checking for identifier" do
      it "raises a NoMethodError if the key is invalid" do
        expect { context.oneTwoThree? }.to raise_error(NoMethodError)
      end

      it "returns nil if the key is not set" do
        expect(context.two?).to be_nil
      end

      it "returns the value if the key is set" do
        expect(context.one?).to eq 1
      end
    end

    describe "fetching identifier" do
      it "raises a NoMethodError if the key is invalid" do
        expect { context.oneTwoThree }.to raise_error(NoMethodError)
      end

      it "raises a NoMethodError if the key is not set" do
        expect { context.two }.to raise_error(NoMethodError)
      end

      it "returns the value if the key is set" do
        expect(context.one).to eq 1
      end
    end

    describe "#merge" do
      context "with symbolized keys" do
        it "sets a value if it does not exist yet" do
          expect(context.two?).to eq(nil)
          new_context = context.merge(two: 2)
          expect(new_context.two).to eq(2)

          # doesn't change the source context
          expect(context.two?).to eq(nil)
        end

        it "sets a value if it does exist" do
          new_context = context.merge(one: 2)
          expect(new_context.one).to eq(2)

          # doesn't change the source context
          expect(context.one).to eq(1)
        end
      end

      context "with stringified keys" do
        it "sets a value if it does not exist yet" do
          expect(context.two?).to eq(nil)
          new_context = context.merge("two" => 2)
          expect(new_context.two).to eq(2)

          # doesn't change the source context
          expect(context.two?).to eq(nil)
        end

        it "sets a value if it does exist" do
          new_context = context.merge("one" => 2)
          expect(new_context.one).to eq(2)

          # doesn't change the source context
          expect(context.one).to eq(1)
        end
      end
    end
  end

  context "with a symbolized context" do
    let(:context) { Simple::Service::Context.new(one: 1) }

    it_behaves_like "context requesting"
  end

  context "with a stringified context" do
    let(:context) { Simple::Service::Context.new("one" => 1) }

    it_behaves_like "context requesting"
  end
end
