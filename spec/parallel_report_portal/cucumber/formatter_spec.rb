RSpec.describe ParallelReportPortal::Cucumber::Formatter do
  let(:formatter) { ParallelReportPortal::Cucumber::Formatter }


  it 'registers event handlers on initialization' do
    config = double('cucumber config object')
    allow(config).to receive(:on_event).with(:gherkin_source_parsed)
    expect(config).to receive(:on_event).with(:test_case_started) { |&block| expect(block).to be_kind_of(Proc) }
    expect(config).to receive(:on_event).with(:test_case_finished) { |&block| expect(block).to be_kind_of(Proc) }
    expect(config).to receive(:on_event).with(:test_step_started) { |&block| expect(block).to be_kind_of(Proc) }
    expect(config).to receive(:on_event).with(:test_step_finished) { |&block| expect(block).to be_kind_of(Proc) }
    expect(config).to receive(:on_event).with(:test_run_started) { |&block| expect(block).to be_kind_of(Proc) }
    expect(config).to receive(:on_event).with(:test_run_finished) { |&block| expect(block).to be_kind_of(Proc) }
    formatter.new(config)
  end

end
