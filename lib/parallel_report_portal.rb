require "parallel_report_portal/clock"
require "parallel_report_portal/configuration"
require "parallel_report_portal/file_utils"
require "parallel_report_portal/http"
require "parallel_report_portal/version"

require 'parallel_tests'

module ParallelReportPortal
  class Error < StandardError; end
  
  extend ParallelReportPortal::HTTP
  extend ParallelReportPortal::FileUtils
  extend ParallelReportPortal::Clock

  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield configuration
  end

  def wait_while_processes_finish
    return unless ENV["TEST_ENV_NUMBER"]
    exit_limit = ENV['EXIT_LIMIT'] || 3
    exit_counter = 0
    initial_sleep = 1
    loop do
      if ParallelTests.number_of_running_processes <= 1
        break
      elsif exit_counter == exit_limit
        ParallelTests.stop_all_processes
        break
      end
      sleep(initial_sleep)
      initial_sleep += 3
    end
  end
  
  at_exit do
    if ParallelReportPortal.parallel?
      if ParallelTests.first_process?
        wait_while_processes_finish
        delete_file(launch_id_file)
        delete_file(hierarchy_file)
      end
    else
      delete_file(launch_id_file)
      delete_file(hierarchy_file)
    end
  end
end
