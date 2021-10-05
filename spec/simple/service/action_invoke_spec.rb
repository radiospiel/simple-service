# rubocop:disable Style/WordArray
require "spec_helper"

describe "Simple::Service.invoke" do
  include ::Simple::Service::RSpecHelper

  let(:service) { InvokeTestService }
  let(:action)  { nil }

  # a shortcut
  def invoke!(args: {}, flags: {})
    @actual = ::Simple::Service.invoke(service, action, args: args, flags: flags)
    # rescue ::StandardError => e
  rescue ::Simple::Service::ArgumentError => e
    @actual = e
  end

  attr_reader :actual

  context "calling an action w/o parameters" do
    # reminder: this is the definition of no_params
    #
    # def no_params
    #   "service2 return"
    # end

    let(:action) { :no_params }

    context "calling without args" do
      it "runs the action" do
        invoke!
        expect(actual).to eq("service2 return")
      end
    end

    context "calling with extra named args" do
      it "ignores extra args" do
        invoke!(args: { "foo" => "foo", "bar" => "bar" })
        expect(actual).to eq("service2 return")
      end
    end

    context "calling with extra flags" do
      it "ignores extra args" do
        invoke!(flags: { "foo" => "foo", "bar" => "bar" })
        expect(actual).to eq("service2 return")
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
        invoke!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
        expect(actual.to_s).to match(/\ba, b\b/)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo", "b" => "bar" })
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the required number of args and flags" do
      it "merges flags and args to provide arguments" do
        invoke!(args: { "a" => "foo" }, flags: { "b" => "bar" })
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo", "b" => "bar", "c" => "baz", "e" => "number4" })
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "calling with extra named args" do
      it "ignores extra args" do
        invoke!(args: { "a" => "foo", "b" => "bar", "c" => "baz", "e" => "number4", "extra3" => 3 })
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end
  end

  context "calling an action w/named parameters" do
    # reminder: this is the definition of named_params
    #
    # def named_params(a:, b:, "c" => "speed-of-light", e: 2.781)
    #   [a, b, c, e]
    # end

    let(:action) { :named_params }

    context "without args" do
      it "raises MissingArguments" do
        invoke!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
        expect(actual.to_s).to match(/\ba, b\b/)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo", "b" => "bar" })
        expect(actual).to eq(["foo", "bar", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo", "b" => "bar", "c" => "baz", "e" => "number4" })
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with extra named args" do
      it "ignores extra args" do
        invoke!(args: { "a" => "foo", "b" => "bar", "c" => "baz", "extra3" => 3 })
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
        invoke!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo" })
        expect(actual).to eq(["foo", "default-b", "speed-of-light", 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo", "b" => "bar", "c" => "baz", "e" => "number4" })
        expect(actual).to eq(%w[foo bar baz number4])
      end
    end

    context "with extra named args" do
      it "ignores extra args" do
        invoke!(args: { "a" => "foo", "b" => "bar", "c" => "baz", "e" => "number4", "extra3" => 3 })
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
        invoke!
        expect(actual).to be_a(::Simple::Service::MissingArguments)
      end
    end

    context "with the required number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo" })
        expect(actual).to eq(["foo", "queen bee", [], 2.781])
      end
    end

    context "with the allowed number of args" do
      it "runs" do
        invoke!(args: { "a" => "foo", "b" => "bar", "args" => ["baz"] }, flags: { "e" => "number4" })
        expect(actual).to eq(["foo", "bar", ["baz"], "number4"])
      end
    end

    context "with variadic args" do
      it "sends the variadic args from the args: parameter" do
        invoke!(args: { "a" => "foo", "b" => "bar", "args" => ["baz", "extra"] }, flags: { "e" => "number4", "extra3" => 2 })
        expect(actual).to eq(["foo", "bar", ["baz", "extra"], "number4"])
      end

      it "sends the variadic args from the flags: parameter" do
        invoke!(args: { "a" => "foo", "b" => "bar" }, flags: { "args" => ["baz", "extra"], "e" => "number4", "extra3" => 2 })
        expect(actual).to eq(["foo", "bar", ["baz", "extra"], "number4"])
      end
    end
  end

  describe "calling with symbolized Hashes" do
    it "raises ArgumentError" do
      hsh = { a: "foo", "b" => "KJH" }

      expect do
        invoke!(args: hsh)
      end.to raise_error(Expectation::Matcher::Mismatch)

      expect do
        invoke!(flags: hsh)
      end.to raise_error(Expectation::Matcher::Mismatch)
    end
  end
end
