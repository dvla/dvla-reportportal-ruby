RSpec.describe ParallelReportPortal::HTTP do

  let(:rp) do
    ParallelReportPortal.configure do |config|
      config.uuid = '0a14044a-65fb-4981-b4b0-e699f99b4e59'
      config.endpoint = 'https://url.local:10000/a/path'
      config.project = 'rp_project'
      config.launch = 'rp_launch_name'
      config.description = 'a description'
      config.attributes = 'key:value, value'
      config.tags = 'one, two'
    end
    ParallelReportPortal
  end

  context 'setting up the HTTP(s) connection' do
    it 'constructs the URL for the project' do
      expect(rp.url).to eq("#{rp.configuration.endpoint}/#{rp.configuration.project}")
    end

    it 'can create the bearer header' do
      expect(rp.authorization_header).to eq("Bearer #{rp.configuration.uuid}")
    end

    context 'creating a HTTP connection object' do
      it 'creates a HTTP connection with the correct headers' do
        conn = rp.http_connection
        expect(conn).to be_kind_of(Faraday::Connection)
        expect(conn.url_prefix.to_s).to eq("#{rp.configuration.endpoint}/#{rp.configuration.project}")
        expect(conn.headers).to include({
          'Authorization' => "Bearer #{rp.configuration.uuid}",
          'Content-Type' => 'application/json'
        })

        expect(conn.builder.handlers).not_to include(Faraday::Request::Multipart, Faraday::Request::UrlEncoded)
      end

      it 'uses a persistent HTTP adapter' do
        conn = rp.http_connection
        expect(conn.adapter).to eq(Faraday::Adapter::NetHttpPersistent)
      end
    end

    context 'creating a multi-part HTTP connection object' do
      it 'creates a HTTP connection with the correct headers' do
        conn = rp.http_multipart_connection
        expect(conn).to be_kind_of(Faraday::Connection)
        expect(conn.url_prefix.to_s).to eq("#{rp.configuration.endpoint}/#{rp.configuration.project}")
        expect(conn.headers).to include({
          'Authorization' => "Bearer #{rp.configuration.uuid}"
        })
        expect(conn.headers).not_to include({
          'Content-Type' => 'application/json'
        })

        expect(conn.builder.handlers).to include(Faraday::Request::Multipart, Faraday::Request::UrlEncoded)
      end

      it 'uses a persistent HTTP adapter' do
        conn = rp.http_multipart_connection
        expect(conn.adapter).to eq(Faraday::Adapter::NetHttpPersistent)
      end
    end
  end

  context 'sending requests to Report Portal' do
    let(:rp_endpoint) { "#{rp.configuration.endpoint}/#{rp.configuration.project}" }
    let(:launch_id) { 'c7687317-7ffa-43d7-af9c-024a59f5b20a' }
    let(:parent_id) { '43345b1e-8d96-4f93-92e6-7cda8cebd6df' }
    let(:item_id) { 'a27a1ad3-ec32-42af-9b27-96afe2a2b285' }

    it 'issues a launch started request' do
      stub_request(:post, "#{rp_endpoint}/launch")
        .to_return(body: {id: item_id, number: 1}.to_json )

      id = rp.req_launch_started(0)
      expect(id).to eq item_id
      expect(WebMock).to have_requested(:post, "#{rp_endpoint}/launch")
        .with( body: {
          name: rp.configuration.launch,
          start_time: 0,
          description: rp.configuration.description,
          mode: rp.configuration.debug ? 'DEBUG' : 'DEFAULT',
          tags: rp.configuration.tags,
          attributes: rp.configuration.attributes
        } )
    end

    it 'issues a launch finished request' do
      stub_request(:put, "#{rp_endpoint}/launch/#{launch_id}/finish")
        .to_return(body: {id: launch_id}.to_json )
      
      rp.req_launch_finished(launch_id, 0)
      expect(WebMock).to have_requested(:put, "#{rp_endpoint}/launch/#{launch_id}/finish")
        .with( body: {end_time: 0} )
    end

    it 'calls the item heirachy method when starting a feature' do
      time = Time.now
      feature = OpenStruct.new(
        description: 'feature description', file: 'file.feature', 
        keyword: 'Feature', name: 'a feature', tags: [])
      expect(rp).to receive(:req_hierarchy)
        .with(
          launch_id, "#{feature.keyword}: #{feature.name}", parent_id, 
          'TEST', [], feature.description, time)
      rp.req_feature_started(launch_id, parent_id, feature, time)
    end

    it 'issues a request to add a child to the hierarchy' do
      stub_request(:post, "#{rp_endpoint}/item/#{parent_id}")
        .to_return(body: {id: item_id}.to_json )
      
      time = 0
      id = rp.req_hierarchy(launch_id, 'child', parent_id, 'TEST', [], 'desc', time )

      expect(id).to eq(item_id)
      expect(WebMock).to have_requested(:post, "#{rp_endpoint}/item/#{parent_id}")
        .with( body: {
          start_time: time,
          name: 'child',
          type: 'TEST',
          launch_id: launch_id,
          tags: [],
          attributes: [],
          description: 'desc'
        } )
    end


    it 'issues a feature finished request' do
      stub_request(:put, "#{rp_endpoint}/item/#{item_id}")
      
      rp.req_feature_finished(item_id, 0)
      expect(WebMock).to have_requested(:put, "#{rp_endpoint}/item/#{item_id}")
        .with( body: {end_time: 0} )
    end

    it 'issues a test case started request' do
      stub_request(:post, "#{rp_endpoint}/item/#{parent_id}")
        .to_return(body: {id: item_id}.to_json )
      time = 0
      test_case = OpenStruct.new(keyword: 'Step', location: 123, tags: [], name: 'test case')

      id = rp.req_test_case_started(launch_id, parent_id, test_case, time)
      expect(id).to eq(item_id)
      expect(WebMock).to have_requested(:post, "#{rp_endpoint}/item/#{parent_id}")
        .with( body: {
          start_time: time,
          tags: test_case.tags,
          name: "#{test_case.keyword}: #{test_case.name}",
          type: 'STEP',
          launch_id: launch_id,
          description: test_case.location.to_s, 
          attributes: test_case.tags
        })
    end


    it 'issues a test case finished request' do
      stub_request(:put, "#{rp_endpoint}/item/#{item_id}")
      
      rp.req_test_case_finished(item_id, 'PASS', 0)
      expect(WebMock).to have_requested(:put, "#{rp_endpoint}/item/#{item_id}")
        .with( body: {end_time: 0, status: 'PASS'} )
    end

    it 'issues a log request' do
      stub_request(:post, "#{rp_endpoint}/log")
      time = 0

      rp.req_log(item_id, 'a message', 'info', time)
      expect(WebMock).to have_requested(:post, "#{rp_endpoint}/log")
        .with( body: {
          item_id: item_id,
          message: 'a message',
          level: 'info',
          time: time
        } )
    end

    # this is a poor test but I can't find a way to test the 
    # multipart upload. There's no test of the request body
    # which is non-trivial which makes me sad :(
    it 'issues a log request with an attachment' do
      stub_request(:post, "#{rp_endpoint}/log")
      t = Tempfile.new
      rp.send_file('info', t.path, 'a label', nil, mime_type = 'image/png')
      expect(WebMock).to have_requested(:post, "#{rp_endpoint}/log")
    end
  end

end
