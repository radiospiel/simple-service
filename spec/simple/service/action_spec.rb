require "spec_helper"

describe Simple::Service::Action do
  let(:service) { SpecService }

  let(:service1) { ::Simple::Service.action(service, :service1) }
  let(:service2) { ::Simple::Service.action(service, :service2) }
  let(:service3) { ::Simple::Service.action(service, :service3) }

  describe "attributes" do
    describe "#service" do
      it "returns the service module" do
        expect(service1.service).to eq(service)
      end
    end

    describe "#name" do
      it "returns the action name" do
        expect(service1.name).to eq(:service1)
      end
    end

    describe "full_name" do
      it "returns the full_name" do
        expect(service1.full_name).to eq("SpecService#service1")
      end
    end

    describe "to_s" do
      it "returns the full_name" do
        expect(service1.to_s).to eq("SpecService#service1")
      end
    end

    describe "#short_description" do
      it "returns the short_description as per source code" do
        expect(service1.short_description).to eq("This is service1")
        expect(service2.short_description).to eq("This is service2 (no full description)")
        expect(service3.short_description).to eq(nil)
      end
    end

    describe "#full_description" do
      it "returns the full_description as per source code" do
        expect(service1.full_description).to eq("Service 1 has a full description")
        expect(service2.full_description).to eq(nil)
        expect(service3.full_description).to eq(nil)
      end
    end
  end
end
