RSpec.describe ParallelReportPortal::AfterLaunch do
  let(:after_launch) { Class.new { extend ParallelReportPortal::AfterLaunch } }

  it 'takes a block' do
    the_block = Proc.new { nil }
    after_launch.after_launch(&the_block)
    expect(after_launch.launch_finished_block).to eq the_block
  end
end
