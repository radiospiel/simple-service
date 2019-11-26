ENV["RACK_ENV"] = "test"
ENV["RAILS_ENV"] = "test"

require "byebug"
require "rspec"

Dir.glob("./spec/support/**/*.rb").sort.each { |path| load path }

require "simple/service"

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run focus: (ENV["CI"] != "true")
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = "random"
  config.example_status_persistence_file_path = ".rspec.data"

  config.backtrace_exclusion_patterns << /spec\/support/
  config.backtrace_exclusion_patterns << /spec_helper/
  config.backtrace_exclusion_patterns << /database_cleaner/

  # config.around(:each) do |example|
  #   example.run
  # end
end
