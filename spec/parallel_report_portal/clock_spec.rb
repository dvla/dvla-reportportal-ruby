RSpec.describe ParallelReportPortal::Clock do
  let(:clock) { Class.new { extend ParallelReportPortal::Clock } }

  it 'tells the time' do
    millisecs = 10
    expect(clock.clock).to be_within(millisecs).of(Time.now.to_f * 1000)
  end
end
