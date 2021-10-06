require "spec_helper"

describe Simple::Workflow::Context do
  RSpec.shared_examples "context requesting" do
    it "inherits from Simple::Immutable" do
      expect(context).to be_a(Simple::Immutable)
    end

    describe "checking for identifier" do
      it "raises an ArgumentError if the key is invalid" do
        expect { context.oneTwoThree? }.to raise_error(ArgumentError)
      end

      it "returns nil if the key is not set" do
        expect(context.two?).to be_nil
      end

      it "returns the value if the key is set" do
        expect(context.one?).to eq 1
      end
    end

    describe "fetching identifier" do
      it "raises an ArgumentError if the identifier is invalid" do
        expect { context.one! }.to raise_error(ArgumentError)
        expect { context.oneTwoThree }.to raise_error(ArgumentError)
      end

      it "raises a NoMethodError if the key is not set" do
        expect { context.two }.to raise_error(NameError)
      end

      it "returns the value if the key is set" do
        expect(context.one).to eq 1
      end
    end

    describe "#merge" do
      context "with symbolized keys" do
        it "sets a value if it does not exist yet" do
          expect(context.two?).to eq(nil)
          new_context = Simple::Workflow::Context.new({two: 2}, context)
          expect(new_context.two).to eq(2)

          # doesn't change the source context
          expect(context.two?).to eq(nil)
        end

        it "sets a value if it does exist" do
          new_context = Simple::Workflow::Context.new({one: 2}, context)
          expect(new_context.one).to eq(2)

          # doesn't change the source context
          expect(context.one).to eq(1)
        end
      end

      context "with stringified keys" do
        it "sets a value if it does not exist yet" do
          expect(context.two?).to eq(nil)
          new_context = Simple::Workflow::Context.new({"two" => 2}, context)
          expect(new_context.two).to eq(2)

          # doesn't change the source context
          expect(context.two?).to eq(nil)
        end

        it "sets a value if it does exist" do
          new_context = Simple::Workflow::Context.new({"one" => 2}, context)
          expect(new_context.one).to eq(2)

          # doesn't change the source context
          expect(context.one).to eq(1)
        end
      end
    end
  end

  context "with a symbolized context" do
    let(:context) { Simple::Workflow::Context.new(one: 1) }

    it_behaves_like "context requesting"
  end

  context "with a stringified context" do
    let(:context) { Simple::Workflow::Context.new("one" => 1) }

    it_behaves_like "context requesting"
  end
end
