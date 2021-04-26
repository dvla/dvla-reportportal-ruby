# ParallelReportPortal

This gem is a Ruby-Cucumber formatter which sends the test output to [Report Portal](https://reportportal.io).

This formatter supports plain 'ol Cucumber tests and those wrapped with [parallel_tests](https://rubygems.org/gems/parallel_tests). 

It also supports Cucumber 3.x and 4+ (Cucumber implementations using cucumber-messages).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parallel_report_portal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install parallel_report_portal

## Usage

### With cucumber

```
cucumber -f ParallelReportPortal::Cucumber::Formatter
```

With cucumber and another formatter (so you can see the testoutput)

```
cucumber -f ParallelReportPortal::Cucumber::Formatter --out /dev/null -f progress
```

### With parallel_tests

```
parallel_cucumber -- -f ParallelReportPortal::Cucumber::Formatter -- features/
 ```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dvla/dvla-reportportal-ruby.
