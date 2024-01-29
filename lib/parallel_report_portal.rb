require 'openssl'
require 'parallel_report_portal/after_launch'
require "parallel_report_portal/clock"
require "parallel_report_portal/configuration"
require "parallel_report_portal/file_utils"
require "parallel_report_portal/http"
require "parallel_report_portal/version"
require 'parallel_tests'

module ParallelReportPortal
  class Error < StandardError; end

  extend ParallelReportPortal::AfterLaunch
  extend ParallelReportPortal::HTTP
  extend ParallelReportPortal::FileUtils
  extend ParallelReportPortal::Clock

  # Returns the configuration object, initializing it if necessary.
  #
  # @return [Configuration] the configuration object
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Configures the Report Portal environment.
  #
  # @yieldparam [Configuration] config the configuration object yielded to the block
  def self.configure(&block)
    yield configuration
  end

  at_exit do
    if ParallelReportPortal.parallel?
      if ParallelTests.first_process?
        ParallelTests.wait_for_other_processes_to_finish

        launch_id = File.read(launch_id_file)
        response = http_repeater { req_launch_finished(launch_id, clock) }
        response.success? ? parse_report_link_from_response(response) : force_stop(launch_id, clock)

        delete_file(launch_id_file)
        delete_file(hierarchy_file)
      end
    else
      delete_file(launch_id_file)
      delete_file(hierarchy_file)
    end
  end
end
