# rubocop:disable Style/WordArray

require "spec_helper"

describe "Simple::Service.invoke3" do
  # the context to use in the around hook below. By default this is nil -
  # which gives us an empty context.
  let(:context) { nil }

  around do |example|
    ::Simple::Service.with_context(context) { example.run }
  end

  let(:service) { InvokeTestService }
  let(:action)  { nil }

  # a shortcut
  def invoke3!(*args, **keywords)
    @actual = ::Simple::Service.invoke3(service, action, *args, **keywords)
    # rescue ::StandardError => e
  rescue ::Simple::Service::ArgumentError => e
    @actual = e
  end

  attr_reader :actual

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
        invoke3!
        expect(actual).to eq("service2 return")
      end
    end

    context "calling with extra positional args" do
      it "raises ExtraArguments" do
        invoke3!("foo", "bar")
        expect(actual).to be_a(::Simple::Service::ExtraArguments)
        expect(actual.to_s).to match(/"foo", "bar"/)
      end
    end

    context "calling with extra named args" do
      it "ignores extra args" do
        invoke3!(foo: "foo", bar: "bar")
        expect(actual).to eq("service2 return")
      end
    end

    context "calling with an additional hash arg" do
      xit "ignores extra args" do
        args = []
        args.push foo: "foo", bar: "bar"
        invoke3!(*args)

        expect(actual).to be_a(::Simple::Service::ExtraArguments)
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
        invoke3!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke3!("foo", "bar")
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke3!("foo", "bar", "baz", "number4")
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with more than the allowed number of args" do
      it "raises ExtraArguments" do
        invoke3!("foo", "bar", "baz", "number4", "extra")
        expect(actual).to be_a(::Simple::Service::ExtraArguments)
      end
    end

    context "calling with extra named args" do
      it "ignores extra args" do
        invoke3!("foo", "bar", "baz", extra3: 3)
        expect(actual).to eq(["foo", "bar", "baz", 2.781])
      end
    end

    context "calling with an additional hash arg" do
      xit "raises ExtraArguments" do
        args = ["foo", "bar", "baz", extra3: 3]
        invoke3!(*args)
        expect(actual).to be_a(::Simple::Service::ExtraArguments)
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
        invoke3!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke3!(a: "foo", b: "bar")
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke3!(a: "foo", b: "bar", c: "baz", e: "number4")
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with more than the allowed number of args" do
      it "runs" do
        invoke3!("foo", "bar", "baz", "number4", "extra")
        expect(actual).to be_a(::Simple::Service::ExtraArguments)
      end
    end

    context "with extra named args" do
      it "ignores extra args" do
        invoke3!(a: "foo", b: "bar", c: "baz", extra3: 3)
        expect(actual).to eq(["foo", "bar", "baz", 2.781])
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
        invoke3!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke3!("foo")
        expect(actual).to eq(["foo", "default-b", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke3!("foo", "bar", "baz", e: "number4")
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with more than the allowed number of args" do
      it "runs" do
        invoke3!("foo", "bar", "baz", "extra", e: "number4")
        expect(actual).to be_a(::Simple::Service::ExtraArguments)
      end
    end

    context "with extra named args" do
      it "ignores extra args" do
        invoke3!("foo", "bar", "baz", e: "number4", extra3: 3)
        expect(actual).to eq(["foo", "bar", "baz", "number4"])
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
        invoke3!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke3!("foo")
        expect(actual).to eq(["foo", "queen bee", [], 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke3!("foo", "bar", "baz", e: "number4")
        expect(actual).to eq(["foo", "bar", ["baz"], "number4"])
      end
    end

    context "with more than the allowed number of args" do
      it "runs" do
        invoke3!("foo", "bar", "baz", "extra", e: "number4")
        expect(actual).to eq(["foo", "bar", ["baz", "extra"], "number4"])
      end
    end

    context "with extra named args" do
      it "ignores extra args" do
        invoke3!("foo", "bar", "baz", e: "number4", extra3: 3)
        expect(actual).to eq(["foo", "bar", ["baz"], "number4"])
      end
    end
  end
end
