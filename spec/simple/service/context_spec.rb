require "spec_helper"

describe Simple::Service::Context do
  let(:context) { Simple::Service::Context.new }
  
  before do
    context.one = 1
  end

  describe "reading" do
    it "returns a value if set" do
      expect(context.one).to eq(1)
    end

    it "returns nil if not set" do
      expect(context.two).to be_nil
    end
  end

  describe "writing" do
    it "sets a value if it does not exist yet" do
      context.two = 2 
      expect(context.two).to eq(2)
    end

    it "raises a ReadOnly error if the value exists and is not equal" do
      expect {
        context.one = 2 
      }.to raise_error(::Simple::Service::Context::ReadOnlyError)
    end

    it "sets the value if it exists and is equal" do
      context.one = 1
      expect(context.one).to eq(1)
    end
  end
end
