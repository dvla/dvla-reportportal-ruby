module ParallelReportPortal
  module Cucumber
    class ArrayDecorator < SimpleDelegator
      def peek
        last
      end
    end
  end
end