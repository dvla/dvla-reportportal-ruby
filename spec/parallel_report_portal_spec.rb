RSpec.describe ParallelReportPortal do
  it 'has a version number' do
    expect(ParallelReportPortal::VERSION).not_to be nil
  end

  context 'extends the correct modules' do
    let(:extensions) { ParallelReportPortal.singleton_class.included_modules }

    it 'extends ParallelReportPortal::HTTP' do
      expect(extensions).to include(ParallelReportPortal::HTTP)
    end

    it 'extends ParallelReportPortal::Clock' do
      expect(extensions).to include(ParallelReportPortal::Clock)
    end

    it 'extends ParallelReportPortal::FileUtils' do
      expect(extensions).to include(ParallelReportPortal::FileUtils)
    end
  end

  context 'is configurable' do
    context 'if not explicitly configured' do
      it 'has default configuration object' do
        expect(ParallelReportPortal.configuration).not_to be_nil
      end

      it 'uses ParallelReportPortal::Configuration' do
        expect(ParallelReportPortal.configuration).to be_kind_of(ParallelReportPortal::Configuration)
      end
    end

    context 'allows configuration' do
      it 'yield a configuration object' do
        expect { |x| ParallelReportPortal.configure(&x) }.to yield_with_args(ParallelReportPortal.configuration)
      end
    end
  end
end
