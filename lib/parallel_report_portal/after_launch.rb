module ParallelReportPortal
  # Handle post launch hooks
  module AfterLaunch

    attr_accessor :launch_finished_block
    attr_accessor :report_url

    def after_launch(&block)
      @launch_finished_block = block
    end

  end
end
