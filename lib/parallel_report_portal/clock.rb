module ParallelReportPortal
  module Clock
  
          
    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
    
    def start_time
      @start_time = ((Time.now.to_f * 1000).to_i).freeze
    end
    
    def start_event_time
      @start_event_time = ParallelReportPortal.monotonic_time.freeze
    end
    
  
    def clock
      (monotonic_time - start_event_time + start_time).round
    end		
  
  end
end