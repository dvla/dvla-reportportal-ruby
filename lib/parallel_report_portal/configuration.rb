module ParallelReportPortal
  # The Configuration class holds the connection properties to communicate with
  # Report Portal and to identify the user and project for reporting.
  # 
  # It attempts to load a configuration file called +report_portal.yml+ first in a
  # local directory called +config+ and if that's not found in the current directory.
  # (Report Portal actually tells you to create a files called +REPORT_PORTAL.YML+ in
  # uppercase -- for this reason the initializer is case insensitive with regards to 
  # the file name)
  # 
  # It will then try an apply the following environment variables, if present (these
  # can be specified in either lowercase for backwards compatibility with the official
  # gem or in uppercase for reasons of sanity)
  # 
  # == Environment variables
  # 
  # RP_UUID:: The UUID of the user associated with this launch
  # RP_ENDPOINT:: the URL of the Report Portal API endpoint
  # RP_PROJECT:: the Report Portal project name -- this must already exist within Report Port and this user must be a member of the project
  # RP_LAUNCH:: The name of this launch 
  # RP_DESCRIPTION:: A textual string describing this launch
  # RP_TAGS:: A set of tags to pass to Report Portal for this launch. If these are set via an environment variable, provide a comma-separated string of tags
  # RP_ATTRIBUTES:: A set of attribute tags to pass to Report Portal for this launch. If these are set via an environment variable, provide a comma-separated string of attributes
  class Configuration
    ATTRIBUTES = [:uuid, :endpoint, :project, :launch, :debug, :description, :tags, :attributes]

    # @return [String] the Report Portal user UUID
    attr_accessor :uuid
    # @return [String] the Report Portal URI - this should include the scheme
    #   e.g. +https://reportportal.local/api/v1+
    attr_accessor :endpoint
    # @return [String] the Report Portal project name.
    #   This must exist and match the project name within
    #   Report Portal.
    attr_accessor :project
    #  @return [String] the launch name for this test run.
    attr_accessor :launch
    # @return [Array<String>] an array of tags to attach to this launch.
    attr_reader :tags
    # @return [Boolean] true if this is a debug run (this launch will appear
    #   on the debug tab in Report Portal).
    attr_reader :debug
    # @return [String] a textual description of this launch.
    attr_accessor :description
    # @return [Array<String>] an array of attributes to attach to this launch
    #   (Report Portal 5)
    attr_reader :attributes


    # Create an instance of Configuration.
    #
    # The initializer will first attempt to load a configuration files called
    # +report_portal.yml+ (case insensitive) in the both the +config+ and current
    # working directory (the former takes precidence). It will then apply
    # any of the environment variable values.
    def initialize
      load_configuration_file
      ATTRIBUTES.each do |attr|
        env_value = get_env("rp_#{attr.to_s}")
        send(:"#{attr}=", env_value) if env_value
      end
    end

    # Sets the tags for the launch. If an array is provided, the array is used,
    # if a string is provided, the string is broken into components by splitting
    # on a comma.
    #
    # e.g.
    #   configuration.tags="one,two, three"
    #   #=> ["one", "two", "three"]
    #
    # param [String | Array<String>] taglist a list of tags to set
    def tags=(taglist)
      if taglist.is_a?(String)
        @tags = taglist.split(',').map(&:strip)
      elsif taglist.is_a?(Array)
        @tags = taglist
      else
        @tags = []
      end
      tags
    end


    # Enables the debug flag which is sent to Report Portal. If this flag is set
    # Report Portal will include this launch in its 'debug' tab.
    #
    # param [Boolean | String] value if the value is a Boolean, it will take that value
    #   if it is a String, it will set values of 'true' to +true+, else all values will be false.
    def debug=(value)
      @debug = if [true, false].include?(value)
                 value
               else
                 value.to_s.downcase.strip == 'true'
               end
    end

    # Sets the attributes for the launch. If an array is provided, the array is used,
    # if a string is provided, the string is broken into components by splitting
    # on a comma.
    #
    # e.g.
    #   configuration.tags="one,two, three"
    #   #=> ["one", "two", "three"]
    #
    # param [String | Array<String>] taglist a list of tags to set
    def attributes=(attrlist)
      if attrlist.is_a?(String)
        @attributes = attrlist.split(',').map(&:strip)
      elsif attrlist.is_a?(Array)
        @attributes = attrlist
      else
        @attributes = []
      end
      attributes
    end

    private

    def get_env(name)
      ENV[name.upcase] || ENV[name.downcase]
    end

    def load_configuration_file
      files = Dir['./config/*'] + Dir['./*']
      files
        .filter { |fn| fn.downcase.end_with?('/report_portal.yml') }
        .first
        .then { |fn| fn ? File.read(fn) : '' }
        .then { |ys| YAML.safe_load(ys, symbolize_names: true) }
        .then do |yaml|
        yaml.transform_keys! { |key| key.downcase }
        ATTRIBUTES.each do |attr|
          yaml_key = if yaml&.has_key?("rp_#{attr}".to_sym)
                       "rp_#{attr}".to_sym
                     else
                       attr
                     end
          send(:"#{attr}=", yaml[yaml_key]) if yaml&.fetch(yaml_key, nil)
        end
      end
    end
  end
end