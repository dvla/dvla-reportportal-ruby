module ParallelReportPortal
  # Common file handling methods
  module FileUtils
  
    # Open a file and get an exclusive lock.
    # if an exclusive lock is not available
    # this method will block until it becomes available.
    # This method will yield to a block where all work should
    # be performed. This method guarantees to unlock and
    # close the file at the end of the yield.
    def file_open_exlock_and_block(filename, mode)
      file = File.new(filename, mode)
      begin
        file.flock(File::LOCK_EX)
        yield file
      ensure
        file.flock(File::LOCK_UN)
        file.close
      end
    end
    
    def parallel?
      !ENV['PARALLEL_PID_FILE'].nil?
    end
  
    
    def launch_id_file
      @lock_file ||= Pathname(Dir.tmpdir) + ("report_portal_tracking_file_#{pid}.lck")
    end
    
    def hierarchy_file
      @hierarchy_file ||= Pathname(Dir.tmpdir) + ("report_portal_hierarchy_file_#{pid}.lck")
    end
    
    def pid
      pid = parallel? ? Process.ppid : Process.pid
    end
    
    def delete_file(filename)
      File.delete(filename) if File.exist?(filename)
    end
  
  end
end