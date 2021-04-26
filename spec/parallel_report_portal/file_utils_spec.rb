RSpec.describe ParallelReportPortal::FileUtils do

  let(:file_utils) { Class.new { extend ParallelReportPortal::FileUtils } }

  it 'opens a file with a mutex lock and yields the file' do
    file_double = double('file to be opened')
    allow(file_double).to receive(:flock)
    allow(file_double).to receive(:close)

    expect(File).to receive(:new).with('/tmp/test.txt', 'r').and_return(file_double)
    expect(file_double).to receive(:flock).with(File::LOCK_EX)
    expect(file_double).to receive(:flock).with(File::LOCK_UN)
    expect(file_double).to receive(:close)

    expect { |x| file_utils.file_open_exlock_and_block('/tmp/test.txt', 'r', &x) }.to yield_with_args(file_double)
  end

  it 'knows if this a parallel test' do
    ENV['PARALLEL_PID_FILE'] = '/tmp/pidfile'
    expect(file_utils.parallel?).to be true
    ENV.delete('PARALLEL_PID_FILE')
    expect(file_utils.parallel?).to be false
  end

  it 'creates a pid file' do
    expect(file_utils.launch_id_file.to_s).to include("report_portal_tracking_file_#{Process.pid}")
    expect(file_utils.launch_id_file).to be_kind_of(Pathname)
  end

  it 'creates a hierarchy file' do
    expect(file_utils.hierarchy_file.to_s).to include("report_portal_hierarchy_file_#{Process.pid}")
    expect(file_utils.hierarchy_file).to be_kind_of(Pathname)
  end

  it 'deletes a file which exists' do
    expect(File).to receive(:exist?).with('/tmp/atestfile.txt').and_return(true)
    expect(File).to receive(:delete).with('/tmp/atestfile.txt')

    file_utils.delete_file('/tmp/atestfile.txt')
  end

  it 'is silent if asked to delete a non-existent file' do
    expect(File).to receive(:exist?).with('/tmp/atestfile.txt').and_return(false)
    expect(File).not_to receive(:delete)

    file_utils.delete_file('/tmp/atestfile.txt')
  end
end
