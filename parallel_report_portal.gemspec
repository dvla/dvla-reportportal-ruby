lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "parallel_report_portal/version"

Gem::Specification.new do |spec|
  spec.name          = "parallel_report_portal"
  spec.version       = ParallelReportPortal::VERSION
  spec.authors       = ["Nigel Brookes-Thomas", "Thomas Feathers"]
  spec.email         = ["nigel.brookes-thomas@dvla.gov.uk"]

  spec.summary       = %q{Run Cucumber Tests in parallel and with Cucumber 3 and 4+}
  spec.description   = %q{A Cucumber formatter which integrates with Report Portal and supports both the parallel_tests gem and cucumber-messages}
  spec.homepage      = "https://github.com/dvla/dvla-reportportal-ruby"

  spec.license     = 'MIT'

  # spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dvla/dvla-reportportal-ruby"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "appraisal", '~> 2.4'
  spec.add_development_dependency "bump", "~> 0.8"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "webmock", "~> 3.12"
  
  spec.add_runtime_dependency 'cucumber', '>= 3.2'
  spec.add_runtime_dependency 'faraday-net_http_persistent', '~> 2.1'
  spec.add_runtime_dependency 'faraday-multipart', '~> 1.0', '>= 1.0.4'
  spec.add_runtime_dependency 'parallel_tests', '>= 2.29.1'
  spec.add_runtime_dependency 'rubytree', '~> 1.0'
  spec.add_runtime_dependency 'net-http-persistent', '~> 4.0'
end
