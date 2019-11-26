require "spec_helper"

describe "Simple::Service::VERSION" do
  it "returns a version number" do
    expect(Simple::Service::VERSION).to match(/\d\.\d\.\d/)
  end
end
