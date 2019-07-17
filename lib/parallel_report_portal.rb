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
  
  at_exit do
    if ParallelReportPortal.parallel?
      if ParallelTests.first_process?
        ParallelTests.wait_for_other_processes_to_finish
        File.delete(ParallelReportPortal.launch_id_file)
        File.delete(ParallelReportPortal.hierarchy_file)
      end
    else
      File.delete(ParallelReportPortal.launch_id_file)
      File.delete(ParallelReportPortal.hierarchy_file)
    end
  end
end
