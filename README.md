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

### Configuration

The formatter supports configuration via a config file or via environment variables

#### Configuration file

It will search for a file called `report_portal.yml` or `REPORT_PORTAL.YML` in `./config` and `./`. It expects this file to contain the standard Report Portal configuration options -- see the Report Portal documentation. Optionally, the config file keys may match those accepted through environment variables -- they may contain 'rp_' and 'RP_'.

#### Environment variables

It will search for the following environment variables which may be in upper or lowercase (the official client defers to lower case, this is available here for compatibility).

* `RP_UUID` - the user's UUID for this Report Portal instance which must be created in advance
* `RP_ENDPOINT` - the endpoint for this Report Portal instance 
* `RP_PROJECT` - the Report Portal project name which must be created in advance and this user added as a member 
* `RP_LAUNCH` - the name of this 'launch'  
* `RP_DEBUG` - *optional* if set to the string value `true` it will instruct Report Portal to add the output of these tests to the debug tab 
* `RP_DESCRIPTION` - *optional* a textual description of the launch 
* `RP_TAGS` - *optional* a string of comma separated tags 
* `RP_ATTRIBUTES` - *optional* a string of comma separated attributes 

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
