RSpec.describe ParallelReportPortal::Configuration do

  context 'knows about configuration attributes' do
    let(:configurable_attributes) { ParallelReportPortal::Configuration::ATTRIBUTES }

    it 'reflects over the settable attributes' do
      expected_attrs = [:uuid, :endpoint, :project, :launch, :debug, :description, :tags, :attributes]
      expect(configurable_attributes).to contain_exactly(*expected_attrs)
    end
  end

  context 'has accessors' do
    let(:config) { ParallelReportPortal::Configuration.new }
    it 'allows setting the UUID' do
      uuid = '0a14044a-65fb-4981-b4b0-e699f99b4e59'
      config.uuid = uuid
      expect(config.uuid).to eq(uuid)
    end

    it 'allows setting the endpoint' do
      endpoint = 'https://url.local:10000/a/path'
      config.endpoint = endpoint
      expect(config.endpoint).to eq(endpoint)
    end

    it 'allows setting the project name' do
      name = 'RP_PROJECT_NAME'
      config.project = name
      expect(config.project).to eq(name)
    end

    it 'allows setting the launch name' do
      launch = 'a test launch'
      config.launch = launch
      expect(config.launch).to eq(launch)
    end

    it 'allows setting the debug flag' do
      debug = true
      config.debug = debug
      expect(config.debug).to eq(debug)
    end

    it 'allows setting the description' do
      description = 'this is a launch description'
      config.description = description
      expect(config.description).to eq(description)
    end

    context 'handles array-like strings and arrays' do
      it 'allows setting the tags as an array' do
        tags = ['one', 'two']
        config.tags = tags
        expect(config.tags).to contain_exactly(*tags)
      end
      
      it 'allows setting the tags as a string' do
        tags = ['one', 'two']
        config.tags = tags.join(', ')
        expect(config.tags).to contain_exactly(*tags)
      end

      it 'allows setting the attributes as an array' do
        attributes = ['one:value', 'two']
        config.attributes = attributes
        expect(config.attributes).to contain_exactly(*attributes)
      end
      
      it 'allows setting the attributes as a string' do
        attributes = ['one:value', 'two']
        config.attributes = attributes.join(', ')
        expect(config.attributes).to contain_exactly(*attributes)
      end
    end
  end

  context 'loading configuration files' do
    it 'does not object if there is no configuration file' do
      expect(Dir).to receive(:[]).with('./config/*').and_return(['.'])
      expect(Dir).to receive(:[]).with('./*').and_return([])
      ParallelReportPortal::Configuration.new
    end

    it 'loads the ./report_portal.yml configuration file' do
      expect(Dir).to receive(:[]).with('./config/*').and_return([])
      expect(Dir).to receive(:[]).with('./*').and_return(['./report_portal.yml'])
      expect(File).to receive(:read).with('./report_portal.yml').and_return(<<~CONFIG)
        uuid: 0a14044a-65fb-4981-b4b0-e699f99b4e59
        endpoint: https://url.local:10000/a/path
        project: rp_project
        launch: rp_launch_name
        description: a description
        attributes: [key:value, value]
      CONFIG
      
      config = ParallelReportPortal::Configuration.new

      aggregate_failures 'values are set' do
        expect(config.uuid).to eq('0a14044a-65fb-4981-b4b0-e699f99b4e59')
        expect(config.endpoint).to eq('https://url.local:10000/a/path')
        expect(config.project).to eq('rp_project')
        expect(config.launch).to eq('rp_launch_name')
        expect(config.description).to eq('a description')
      end
    end

    it 'loads the ./config/report_portal.yml configuration file' do
      expect(Dir).to receive(:[]).with('./config/*').and_return(['./config/report_portal.yml'])
      expect(Dir).to receive(:[]).with('./*').and_return([])
      expect(File).to receive(:read).with('./config/report_portal.yml').and_return(<<~CONFIG)
        uuid: 0a14044a-65fb-4981-b4b0-e699f99b4e59
        endpoint: https://url.local:10000/a/path
        project: rp_project
        launch: rp_launch_name
        description: a description
        attributes: [key:value, value]
      CONFIG
      
      config = ParallelReportPortal::Configuration.new

      aggregate_failures 'values are set' do
        expect(config.uuid).to eq('0a14044a-65fb-4981-b4b0-e699f99b4e59')
        expect(config.endpoint).to eq('https://url.local:10000/a/path')
        expect(config.project).to eq('rp_project')
        expect(config.launch).to eq('rp_launch_name')
        expect(config.description).to eq('a description')
      end
    end

    it 'loads the ./report_portal.yml configuration file with rp_ in keys' do
      expect(Dir).to receive(:[]).with('./config/*').and_return([])
      expect(Dir).to receive(:[]).with('./*').and_return(['./report_portal.yml'])
      expect(File).to receive(:read).with('./report_portal.yml').and_return(<<~CONFIG)
        rp_uuid: 0a14044a-65fb-4981-b4b0-e699f99b4e59
        rp_endpoint: https://url.local:10000/a/path
        rp_project: rp_project
        rp_launch: rp_launch_name
        rp_description: a description
        rp_attributes: [key:value, value]
      CONFIG

      config = ParallelReportPortal::Configuration.new

      aggregate_failures 'values are set' do
        expect(config.uuid).to eq('0a14044a-65fb-4981-b4b0-e699f99b4e59')
        expect(config.endpoint).to eq('https://url.local:10000/a/path')
        expect(config.project).to eq('rp_project')
        expect(config.launch).to eq('rp_launch_name')
        expect(config.description).to eq('a description')
      end
    end

    it 'loads the ./report_portal.yml configuration file with RP_ in keys and all caps' do
      expect(Dir).to receive(:[]).with('./config/*').and_return([])
      expect(Dir).to receive(:[]).with('./*').and_return(['./report_portal.yml'])
      expect(File).to receive(:read).with('./report_portal.yml').and_return(<<~CONFIG)
        RP_UUID: 0a14044a-65fb-4981-b4b0-e699f99b4e59
        RP_ENDPOINT: https://url.local:10000/a/path
        RP_PROJECT: rp_project
        RP_LAUNCH: rp_launch_name
        RP_DESCRIPTION: a description
        RP_ATTRIBUTES: [key:value, value]
      CONFIG

      config = ParallelReportPortal::Configuration.new

      aggregate_failures 'values are set' do
        expect(config.uuid).to eq('0a14044a-65fb-4981-b4b0-e699f99b4e59')
        expect(config.endpoint).to eq('https://url.local:10000/a/path')
        expect(config.project).to eq('rp_project')
        expect(config.launch).to eq('rp_launch_name')
        expect(config.description).to eq('a description')
      end
    end

    it 'prefers ./config/report_portal.yml over ./report_portal.yml' do
      expect(Dir).to receive(:[]).with('./config/*').and_return(['./config/report_portal.yml'])
      expect(Dir).to receive(:[]).with('./*').and_return(['./report_portal.yml'])
      expect(File).to receive(:read).with('./config/report_portal.yml').and_return('')
      
      config = ParallelReportPortal::Configuration.new
    end

    it 'accepts the name ./config/REPORT_PORTAL.YML' do
      expect(Dir).to receive(:[]).with('./config/*').and_return(['./config/REPORT_PORTAL.YML'])
      expect(Dir).to receive(:[]).with('./*').and_return([])
      expect(File).to receive(:read).with('./config/REPORT_PORTAL.YML').and_return('')
      
      config = ParallelReportPortal::Configuration.new
    end

    it 'accepts the name ./REPORT_PORTAL.YML' do
      expect(Dir).to receive(:[]).with('./config/*').and_return([])
      expect(Dir).to receive(:[]).with('./*').and_return(['./REPORT_PORTAL.YML'])
      expect(File).to receive(:read).with('./REPORT_PORTAL.YML').and_return('')
      
      config = ParallelReportPortal::Configuration.new
    end
  end

  context 'allows environment variables to set values' do
    it 'accepts RP_PROJECT' do
      project = ENV['RP_PROJECT'] = 'project_name'
      config = ParallelReportPortal::Configuration.new
      expect(config.project).to eq(project)
    end  

    it 'accepts rp_project' do
      project = ENV['rp_project'] = 'project_name'
      config = ParallelReportPortal::Configuration.new
      expect(config.project).to eq(project)
    end  

    it 'accepts RP_UUID' do
      uuid = ENV['RP_UUID'] = '0a14044a-65fb-4981-b4b0-e699f99b4e59'
      config = ParallelReportPortal::Configuration.new
      expect(config.uuid).to eq(uuid)
    end  

    it 'accepts rp_uuid' do
      uuid = ENV['rp_uuid'] = '0a14044a-65fb-4981-b4b0-e699f99b4e59'
      config = ParallelReportPortal::Configuration.new
      expect(config.uuid).to eq(uuid)
    end

    it 'accepts RP_DESCRIPTION' do
      desc = ENV['RP_DESCRIPTION'] = 'the description'
      config = ParallelReportPortal::Configuration.new
      expect(config.description).to eq(desc)
    end

    it 'accepts rp_description' do
      desc = ENV['rp_description'] = 'the description'
      config = ParallelReportPortal::Configuration.new
      expect(config.description).to eq(desc)
    end

    it 'accepts RP_ENDPOINT' do
      ep = ENV['RP_ENDPOINT'] = 'https://rp.local:10000/a/path'
      config = ParallelReportPortal::Configuration.new
      expect(config.endpoint).to eq(ep)
    end

    it 'accepts rp_endpoint' do
      ep = ENV['rp_endpoint'] = 'https://rp.local:10000/a/path'
      config = ParallelReportPortal::Configuration.new
      expect(config.endpoint).to eq(ep)
    end

    it 'accepts RP_LAUNCH' do
      name = ENV['RP_LAUNCH'] = 'a launch name'
      config = ParallelReportPortal::Configuration.new
      expect(config.launch).to eq(name)
    end

    it 'accepts rp_launch' do
      name = ENV['rp_launch'] = 'a launch name'
      config = ParallelReportPortal::Configuration.new
      expect(config.launch).to eq(name)
    end

    it 'accepts RP_DEBUG' do
      ENV['RP_DEBUG'] = 'true'
      config = ParallelReportPortal::Configuration.new
      expect(config.debug).to be true
    end

    it 'accepts rp_debug' do
      ENV['rp_debug'] = 'true'
      config = ParallelReportPortal::Configuration.new
      expect(config.debug).to be true
    end

    it 'accepts RP_TAGS' do
      ENV['RP_TAGS'] = 'one, two, three'
      config = ParallelReportPortal::Configuration.new
      expect(config.tags).to contain_exactly('one', 'two', 'three')
    end

    it 'accepts rp_tags' do
      ENV['rp_tags'] = 'one, two, three'
      config = ParallelReportPortal::Configuration.new
      expect(config.tags).to contain_exactly('one', 'two', 'three')
    end

    it 'accepts RP_ATTRIBUTES' do
      ENV['RP_ATTRIBUTES'] = 'one, two, three:value'
      config = ParallelReportPortal::Configuration.new
      expect(config.attributes).to contain_exactly('one', 'two', 'three:value')
    end

    it 'accepts rp_attributes' do
      ENV['rp_attributes'] = 'one, two, three:value'
      config = ParallelReportPortal::Configuration.new
      expect(config.attributes).to contain_exactly('one', 'two', 'three:value')
    end
  end

end
