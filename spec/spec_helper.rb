require "bundler/setup"
require "parallel_report_portal"
require "parallel_report_portal/clock"
require "parallel_report_portal/http"
require "parallel_report_portal/file_utils"

require 'yaml'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
