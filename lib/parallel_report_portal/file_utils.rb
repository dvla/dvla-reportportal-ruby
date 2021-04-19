module ParallelReportPortal
  # Common file handling methods
  module FileUtils
  
    # Open a file with an exclusive lock and yield the open
    # file to the block. If the system is unable to access the 
    # file it will block until the lock is removed. This method
    # guarantees that the lock will be removed.
    # 
    # @param [String] filename the name of the file to open
    # @param [String] mode the mode to open the file with (e.g. +r+, +w++)
    # @yieldparam [File] file the opened file
    def file_open_exlock_and_block(filename, mode, &block)
      file = File.new(filename, mode)
      begin
        file.flock(File::LOCK_EX)
        yield(file) if block_given?
      ensure
        file.flock(File::LOCK_UN)
        file.close
      end
    end
    
    # Attempts to determin if the current environment is running under a
    # parallel testing environment
    # 
    # @return [Boolean] true if parallel
    def parallel?
      !ENV['PARALLEL_PID_FILE'].nil?
    end
  
    # Returns a pathname for the pid for this launch, initialising if necesssary.
    # 
    # @return [Pathname] the pid pathname
    def launch_id_file
      @lock_file ||= Pathname(Dir.tmpdir) + ("report_portal_tracking_file_#{pid}.lck")
    end
    
    # Returns a pathname for the hierarchy of this launch, initialising if necesssary.
    # 
    # @return [Pathname] the hierarchy pathname
    def hierarchy_file
      @hierarchy_file ||= Pathname(Dir.tmpdir) + ("report_portal_hierarchy_file_#{pid}.lck")
    end
    
    # Gets the pid of this process or the parent pid if running in parallel mode.
    # 
    # @return [Integer] the pid
    def pid
      pid = parallel? ? Process.ppid : Process.pid
    end
    
    # Helper for deleting a file. It will not throw an exception
    # if the file does not exist.
    # 
    # @param [String] the filename to delete
    def delete_file(filename)
      File.delete(filename) if File.exist?(filename)
    end
  
  end
end