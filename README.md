# ParallelReportPortal

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/parallel_report_portal`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

The gem is published to the internal Nexus gem server. To use this gem in your project you must make sure that the Nexus server is included at the top of your `Gemfile`.

```ruby
source 'https://rubygems.org'

# add the internal gem server (for internal gems)
# bundler prefers last 'source' first
source 'https://nexus.tooling.dvla.gov.uk/repository/gem-private/'
```

Add this line to your application's Gemfile:

```ruby
gem 'parallel_report_portal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install parallel_report_portal

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/parallel_report_portal.
