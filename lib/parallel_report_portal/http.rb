require 'logger'
require 'tempfile'

module ParallelReportPortal
  # A collection of methods for communicating with the ReportPortal 
  # REST interface.
  module HTTP

    # Creating class level logger and setting log level
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::ERROR

    def url
      "#{ParallelReportPortal.configuration.endpoint}/#{ParallelReportPortal.configuration.project}"
    end

    def authorization_header
      "Bearer #{ParallelReportPortal.configuration.uuid}"
    end

    # Get a preconstructed Faraday HTTP connection
    # which has the endpont and headers ready populated.
    # This object is memoized.
    def http_connection
      @http_connection ||= Faraday.new(
        url: url,
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => authorization_header
        }
      ) do |f|
        f.adapter :net_http_persistent, pool_size: 5 do |http|
          # yields Net::HTTP::Persistent
          http.idle_timeout = 100
        end
      end
    end

    # Get a preconstructed Faraday HTTP multipart connection
    # which has the endpont and headers ready populated.
    # This object is memoized.
    def http_multipart_connection
      @http_multipart_connection ||= Faraday.new(
        url: url,
        headers: {
          'Authorization' => authorization_header
        }
      ) do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.adapter :net_http_persistent, pool_size: 5 do |http|
          # yields Net::HTTP::Persistent
          http.idle_timeout = 100
        end
      end
    end

    # Send a request to ReportPortal to start a launch.
    # Will raise an exception if a launch cannot be started
    # or return the launch id if successful
    def req_launch_started(time)
      resp = http_connection.post('launch') do |req|
              req.body = {
                name: ParallelReportPortal.configuration.launch, 
                start_time: time, 
                tags: ParallelReportPortal.configuration.tags, 
                description: ParallelReportPortal.configuration.description, 
                mode: (ParallelReportPortal.configuration.debug == 'true' ? 'DEBUG' : 'DEFAULT' )
              }.to_json
            end
      if resp.success?
        JSON.parse(resp.body)['id']
      else
        @@logger.error("Launch failed with response code #{resp.status} -- message #{resp.body}")
      end
    end
    
    # Request a launch be terminated. 
    def req_launch_finished(launch_id, time)
      resp = ParallelReportPortal.http_connection.put("launch/#{launch_id}/finish") do |req|
        req.body = { end_time: time }.to_json
      end
    end
    
    # Send a request to ReportPortal to start a feature.
    # Will raise an exception if a launch cannot be started
    # or return the feature id if successful
    def req_feature_started(launch_id, parent_id, feature, time)
        description = if feature.description
                        feature.description.split("\n").map(&:strip).join(' ')
                      else
                        feature.file
                      end

        req_hierarchy(launch_id,
                      "#{feature.keyword}: #{feature.name}",
                      parent_id,
                      'TEST',
                      feature.tags.map(&:name),
                      description,
                      time )
    end
    
    def req_hierarchy(launch_id, name, parent, type, tags, description, time )
      resource = 'item'
      resource += "/#{parent}" if parent
      resp = ParallelReportPortal.http_connection.post(resource) do |req|
        req.body = {
          start_time: time,
          name: name,
          type: type,
          launch_id: launch_id,
          tags: tags,
          description: description
        }.to_json
      end
      
      if resp.success?
        JSON.parse(resp.body)['id']
      else
        @@logger.warn("Starting a heirarchy failed with response code #{resp.status} -- message #{resp.body}")
      end
    end
  
    # Request that a feature be finished
    def req_feature_finished(feature_id, time)
      resp = ParallelReportPortal.http_connection.put("item/#{feature_id}") do |req|
        req.body = { end_time: time }.to_json
      end
    end
  
    # Send a request to ReportPortal to start a test case.
    # Will raise an exception if a launch cannot be started
    # or return the test case id if successful
    def req_test_case_started(launch_id, feature_id, test_case, time)
      resp = ParallelReportPortal.http_connection.post("item/#{feature_id}") do |req|
          req.body = {
            start_time: time,
            tags: test_case.tags.map(&:name),
            name: "#{test_case.keyword}: #{test_case.name}",
            type: 'STEP',
            launch_id: launch_id,
            description: test_case.location.to_s
          }.to_json
        end
        if resp.success?
          @test_case_id = JSON.parse(resp.body)['id'] if resp.success?
        else
          @@logger.warn("Starting a test case failed with response code #{resp.status} -- message #{resp.body}")
        end
    end
    
    # Request that the test case be finished
    def req_test_case_finished(test_case_id, status, time)
      resp = ParallelReportPortal.http_connection.put("item/#{test_case_id}") do |req|
        req.body = {
          end_time: time,
          status: status
        }.to_json
      end
    end
    
    
    def req_log(test_case_id, detail, level, time)
      resp = ParallelReportPortal.http_connection.post('log') do |req|
        req.body = {
          item_id: test_case_id,
          message: detail,
          level: level,
          time: time,
        }.to_json
      end
    end

    def send_file(status, path, label = nil, time = ParallelReportPortal.clock, mime_type = 'image/png')
      unless File.file?(path)
        extension = ".#{MIME::Types[mime_type].first.extensions.first}"
        temp = Tempfile.open(['file',extension])
        temp.binmode
        temp.write(Base64.decode64(path))
        temp.rewind
        path = temp
      end

      File.open(File.realpath(path), 'rb') do |file|
        label ||= File.basename(file)

        json = { level: status, message: label, item_id: @test_case_id, time: time, file: { name: File.basename(file) } }

        json_file = Tempfile.new
        json_file << [json].to_json
        json_file.rewind

        resp = http_multipart_connection.post("log") do |req|
          req.body = {
            json_request_part: Faraday::UploadIO.new(json_file, 'application/json'),
            file: Faraday::UploadIO.new(file, mime_type)
          }
        end
      end
    end
  end
end
