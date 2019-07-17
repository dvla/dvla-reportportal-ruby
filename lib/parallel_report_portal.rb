require "parallel_report_portal/version"

require 'parallel_tests'

module ParallelReportPortal
  class Error < StandardError; end
  
      
      def self.monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
end
