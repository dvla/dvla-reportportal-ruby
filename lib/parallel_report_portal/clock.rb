module ParallelReportPortal
  # This module is responsilbe for the timekeeping for the tests.
  module Clock
    # Get the current time.
    # 
    # This is based on the Unix time stamp and is in milliseconds.
    # 
    # @return [Integer] the number of milliseconds since the Unix epoc.
    def clock
      (Time.now.to_f * 1000).to_i
    end		
  end
end