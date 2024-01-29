RSpec.describe ParallelReportPortal::Cucumber::Report do
  let(:report) { ParallelReportPortal::Cucumber::Report.new }

  it 'initializes with a start time' do
    r = ParallelReportPortal::Cucumber::Report.new
    expect(r).not_to be_nil
  end

  context 'handling launch started events' do
    after(:example) do
      File.delete(ParallelReportPortal.launch_id_file)
    end

    context 'as the first launch event' do
      let(:uuid) { 'b56818b2-391e-4844-8a6e-144afaf504ed' }

      it 'records the launch id' do
        allow(ParallelReportPortal).to receive(:req_launch_started)
          .and_return(uuid)

        report.launch_started(0)
        launch_id = File.read(ParallelReportPortal.launch_id_file)
        expect(launch_id).to eq uuid
      end
    end

    context 'as a subsequent launch (due to parallel running)' do
      let(:uuid) { 'fdaa0e9a-48c8-4e7d-9ea8-0fd8a2919af9' }
      it 'retrieves the existing launch id' do
        File.write(ParallelReportPortal.launch_id_file, uuid)

        expect(report.launch_started(0)).to eq(uuid)
      end
    end
  end

  context 'handling launch finished events' do
    let(:uuid) { 'b56818b2-391e-4844-8a6e-144afaf504ed' }

    it 'terminates any existing child items before terminating the launch' do
      tree = Tree::TreeNode.new( 'root' )
      tree << Tree::TreeNode.new('child', 'child_node_uuid')

      report.instance_variable_set(:@launch_id, uuid)
      report.instance_variable_set(:@tree, tree)

      expect(ParallelReportPortal).to receive(:req_feature_finished)
        .with('child_node_uuid', 0).once

      report.launch_finished(0)
    end
  end



  let(:launch_id) { 'c7687317-7ffa-43d7-af9c-024a59f5b20a' }
  let(:parent_id) { '43345b1e-8d96-4f93-92e6-7cda8cebd6df' }
  let(:item_id) { 'a27a1ad3-ec32-42af-9b27-96afe2a2b285' }
  it 'handles feature started events' do
    file = OpenStruct.new(file: 'foo.feature')
    feature = OpenStruct.new(location: file)

    expect(ParallelReportPortal).to receive(:req_feature_started).
      with(nil, nil, feature, 0)
    report.feature_started(feature, 0)
  end

end