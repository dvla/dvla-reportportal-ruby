module ParallelReportPortal
  class Configuration
    attr_accessor :uuid, :endpoint, :project, :launch, :tags, :debug, :description
  
    def initialize
      @uuid = ENV['RP_UUID'] || ENV['rp_uuid']
      @endpoint = ENV['RP_ENDPOINT'] || ENV['rp_endpoint']
      @project = ENV['RP_PROJECT'] || ENV['rp_project']
      @launch = ENV['RP_LAUNCH'] || ENV['rp_launch']
      @debug = ENV['RP_DEBUG'] || ENV['rp_debug']
      @description = ENV['RP_DESCRIPTION'] || ENV['rp_description']
      tags = ENV['RP_TAGS'] || ENV['rp_tags']
      if tags
        @tags = tags.split(',').each(&:chomp)
      else
        @tags = []
      end
    end
  end
end