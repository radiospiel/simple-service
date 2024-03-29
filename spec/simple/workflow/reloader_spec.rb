require "spec_helper"

require_relative "reloader_spec/example1"
require_relative "reloader_spec/example2"

describe "Simple::Service::Reloader" do
  describe ".locate" do
    def locate(mod)
      Simple::Workflow::Reloader.locate(mod)
    end

    it "Returns all source files of a module" do
      root = Dir.getwd

      expected = [
        "#{root}/lib/simple/workflow/reloader.rb"
      ]
      expect(locate(Simple::Workflow::Reloader)).to contain_exactly(*expected)

      expected = [
        "#{__dir__}/reloader_spec/example1.rb",
        "#{__dir__}/reloader_spec/example2.rb"
      ]
      expect(locate(ReloaderSpecExample1)).to contain_exactly(*expected)

      expected = [
        "#{__dir__}/reloader_spec/example2.rb"
      ]
      expect(locate(ReloaderSpecExample2)).to contain_exactly(*expected)

      expected = [
        "#{__dir__}/reloader_spec/example1.rb"
      ]
      expect(locate(ReloaderSpecExample3)).to contain_exactly(*expected)
    end
  end

  describe ".reload" do
    def reload(mod)
      Simple::Workflow::Reloader.reload(mod)
    end

    it "Reloads a module" do
      # [TODO] this doesn't really check reloading...
      reload Simple::Workflow::Reloader
    end
  end
end
