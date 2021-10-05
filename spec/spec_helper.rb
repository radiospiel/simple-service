ENV["RACK_ENV"] = "test"
ENV["RAILS_ENV"] = "test"

require "pry-byebug"
require "rspec"

require "simplecov"

SimpleCov.start do
  # return true to remove src from coverage
  add_filter do |src|
    next true if src.filename =~ /\/spec\//

    false
  end

  # minimum_coverage 90
end

require "simple/service"

Dir.glob("./spec/support/**/*.rb").sort.each { |path| load path }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run focus: (ENV["CI"] != "true")
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = "random"
  config.example_status_persistence_file_path = ".rspec.data"

  config.backtrace_exclusion_patterns << /spec\/support/
  config.backtrace_exclusion_patterns << /spec\/helpers/
  config.backtrace_exclusion_patterns << /spec_helper/

  # config.around(:each) do |example|
  #   example.run
  # end
end
