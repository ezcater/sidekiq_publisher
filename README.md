# sidekiq_publisher

This gem provides support to enqueue jobs for Sidekiq by first staging the job
in Postgres and relying on a separate process to communicate with Sidekiq/Redis.

The publisher process is alerted that a job is available to be published using
Postgres NOTIFY/LISTEN.

This approach has the benefit that jobs can be published as part of a transaction
that modifies the system of record for the application. It also allows jobs to
be created even when Sidekiq/Redis is temporarily unavailable. The separate
publisher process handles retries and ensure that each job is delivered to Sidekiq.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "sidekiq_publisher"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq_publisher


Run the generator to create migrations for the jobs table and notifications:

    $ rails generate sidekiq_publisher:install

## Configuration

This gem uses the following configuration:

* **logger**: the logger for this gem to use.
* **exception_reporter**: a Proc that will be called with an exception
* **batch_size**: the maximum number of jobs that will be enqueued to Sidekiq
  together
* **job_retention_period**: the duration that published jobs will be kept in
  Postgres after they have been enqueued to Sidekiq
    
## Usage

### ActiveJob Adapter

This gem includes an adapter to use `SidekiqPublisher` with `ActiveJob`. This
adapter must be explicitly required:

```ruby
require "active_job/queue_adapters/sidekiq_publisher_adapter"
```

The adapter can also be required via your Gemfile:

```ruby
gem "sidekiq_publisher", require: ["sidekiq_publisher", "active_job/queue_adapters/sidekiq_publisher_adapter"]
```

The adapter to use with `ActiveJob` must be specified in Rails configuration

```ruby
# application.rb
config.active_job.queue_adapter = :sidekiq_publisher

# or directly in configuration
Rails.application.config.active_job.queue_adapter = :sidekiq_publisher
```

### SidekiqPublisher::Worker

Sidekiq workers are usually defined by including `Sidekiq::Worker` in a class.

To use the `SidekiqPublisher`, this can be replaced by including
`SidekiqPublisher::Worker`. The usual `perform_async`, etc methods will be
available on the class but jobs will be staged in the Postgres table.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ezcater/sidekiq_publisher.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

