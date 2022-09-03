# rubocop:disable Style/WordArray

require "spec_helper"

describe "Simple::Service.invoke3" do
  let(:service) { InvokeTestService }
  let(:action)  { nil }

  # when calling #invoke3 using positional arguments they will be matched against
  # positional arguments of the invoke3d method - but they will not be matched
  # against named arguments.
  #
  # When there are not enough positional arguments to match the number of required
  # positional arguments of the method we raise an ArgumentError.
  #
  # When there are more positional arguments provided than the number accepted
  # by the method we raise an ArgumentError.

  context "calling an action w/o parameters" do
    # reminder: this is the definition of no_params
    #
    # def no_params
    #   "service2 return"
    # end

    let(:action) { :no_params }

    context "calling without args" do
      it "runs the action" do
        actual = ::Simple::Service.invoke3(service, action)
        expect(actual).to eq("service2 return")
      end
    end

    context "calling with extra positional args" do
      it "raises ExtraArguments" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar")
        }.to raise_error(::Simple::Service::ExtraArgumentError, /"foo", "bar"/)
      end
    end

    context "calling with extra named args" do
      it "raises an ExtraArguments error" do
        expect {
          ::Simple::Service.invoke3(service, action, foo: "foo", bar: "bar")
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end

    context "calling with an additional hash arg" do
      it "ignores extra args" do
        expect {
          args = []
          args.push foo: "foo", bar: "bar"
          ::Simple::Service.invoke3(service, action, *args)
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end
  end

  context "calling an action w/positional parameters" do
    # reminder: this is the definition of positional_params
    #
    # def positional_params(a, b, c = "speed-of-light", e = 2.781)
    #   [a, b, c, e]
    # end

    let(:action) { :positional_params }

    context "without args" do
      it "raises MissingArguments" do
        expect {
          ::Simple::Service.invoke3(service, action)
        }.to raise_error(::Simple::Service::MissingArgumentError)
      end
    end

    context "with the required number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo", "bar")
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", "number4")
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with more than the allowed number of args" do
      it "raises ExtraArguments" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", "number4", "extra")
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end

    context "calling with extra named args" do
      it "ignores extra args" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", extra3: 3)
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end

    context "calling with an additional hash arg" do
      it "raises ExtraArguments" do
        expect {
          args = ["foo", "bar", "baz", extra3: 3]
          ::Simple::Service.invoke3(service, action, *args)
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end
  end

  context "calling an action w/named parameters" do
    # reminder: this is the definition of named_params
    #
    # def named_params(a:, b:, c: "speed-of-light", e: 2.781)
    #   [a, b, c, e]
    # end

    let(:action) { :named_params }

    context "without args" do
      it "raises MissingArguments" do
        expect {
          ::Simple::Service.invoke3(service, action)
        }.to raise_error(::Simple::Service::MissingArgumentError)
      end
    end

    context "with the required number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, a: "foo", b: "bar")
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, a: "foo", b: "bar", c: "baz", e: "number4")
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with more than the allowed number of args" do
      it "runs" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", "number4", "extra")
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end

    context "with extra named args" do
      it "ignores extra args" do
        expect {
          ::Simple::Service.invoke3(service, action, a: "foo", b: "bar", c: "baz", extra3: 3)
        }.to raise_error(::Simple::Service::ArgumentError)
      end
    end
  end

  context "calling an action w/mixed and optional parameters" do
    # reminder: this is the definition of named_params
    #
    # def mixed_optional_params(a, b = "default-b", c = "speed-of-light", e: 2.781)
    #   [a, b, c, e]
    # end

    let(:action) { :mixed_optional_params }

    context "without args" do
      it "raises MissingArguments" do
        expect {
          ::Simple::Service.invoke3(service, action)
        }.to raise_error(::Simple::Service::MissingArgumentError)
      end
    end

    context "with the required number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo")
        expect(actual).to eq(["foo", "default-b", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", e: "number4")
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with more than the allowed number of args" do
      it "raises an ExtraArguments error" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", "extra", e: "number4")
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end

    context "with extra named args" do
      it "raises an ExtraArguments error" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", e: "number4", extra3: 3)
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end
  end

  context "calling an action w/mixed and variadic parameters" do
    # reminder: this is the definition of variadic_params
    #
    # def variadic_params(a, b = "queen bee", *args, e: 2.781)
    #   [a, b, args, e]
    # end

    let(:action) { :variadic_params }

    context "without args" do
      it "raises MissingArguments" do
        expect {
          ::Simple::Service.invoke3(service, action)
        }.to raise_error(::Simple::Service::MissingArgumentError)
      end
    end

    context "with the required number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo")
        expect(actual).to eq(["foo", "queen bee", [], 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", e: "number4")
        expect(actual).to eq(["foo", "bar", ["baz"], "number4"])
      end
    end

    context "with more than the allowed number of args" do
      it "runs" do
        actual = ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", "extra", e: "number4")
        expect(actual).to eq(["foo", "bar", ["baz", "extra"], "number4"])
      end
    end

    context "with extra named args" do
      it "raises an ExtraArguments error" do
        expect {
          ::Simple::Service.invoke3(service, action, "foo", "bar", "baz", e: "number4", extra3: 3)
        }.to raise_error(::Simple::Service::ExtraArgumentError)
      end
    end
  end
end
