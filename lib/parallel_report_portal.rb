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
    # ENV['RP_PROC_WAIT_TO_CLOSE_RETRY_LIMIT'] is the break out limit of retries before closing down
    exit_limit = ENV['RP_PROC_WAIT_TO_EXIT_RETRY_LIMIT'] || 3
    exit_counter = 0
    # ENV['RP_PROC_WAIT_TO_CLOSE_SLEEP'] Is the initial sleep in the loop to retry
    # and check if the processes have completed, this will be incremented by 30 secs
    # every loop.
    initial_wait_time = ENV['RP_PROC_WAIT_TO_EXIT_SLEEP'] || 30
    loop do
      if ParallelTests.number_of_running_processes <= 1
        break
      elsif exit_counter == exit_limit
        ParallelTests.stop_all_processes
        break
      end
      sleep(initial_wait_time)
      exit_counter += 1
      initial_wait_time += 30
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
