lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "parallel_report_portal/version"

Gem::Specification.new do |spec|
  spec.name          = "parallel_report_portal"
  spec.version       = ParallelReportPortal::VERSION
  spec.authors       = ["Nigel Brookes-Thomas"]
  spec.email         = ["nigel.brookes-thomas@dvla.gov.uk"]

  spec.summary       = %q{Parallel Tests integration with ReportPortal.}
  spec.description   = %q{This formatter will cope with both parallel and normal cucumber.}
  spec.homepage      = "https://collaboration.dvla.gov.uk/bitbucket/projects/QE/repos/dvla-reportportal-ruby/browse"

  spec.metadata["allowed_push_host"] = "https://nexus-internal.iep.dvla.gov.uk/nexus/content/groups/gems"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://collaboration.dvla.gov.uk/bitbucket/projects/QE/repos/dvla-reportportal-ruby/browse"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bump", "~> 0.8"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.12"
  
  spec.add_runtime_dependency 'faraday', '~> 1.0'
  spec.add_runtime_dependency 'parallel_tests', '~> 2.29.1'
  spec.add_runtime_dependency 'rubytree', '~> 1.0'
  spec.add_runtime_dependency 'net-http-persistent', '~> 4.0'
end
