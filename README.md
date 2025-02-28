# sidekiq_publisher

> [!WARNING]
> This gem has been archived by ezCater and will no longer be receiving updates.

[![Gem Version][gem_badge]][gem_link]

[gem_badge]: https://badge.fury.io/rb/sidekiq_publisher.svg
[gem_link]: https://badge.fury.io/rb/sidekiq_publisher

This gem provides support to enqueue jobs for Sidekiq by first staging the job
in Postgres and relying on a separate process to communicate with Sidekiq/Redis.

The publisher process is alerted that a job is available to be published using
Postgres NOTIFY/LISTEN.

This approach has the benefit that jobs can be published as part of a transaction
that modifies the system of record for the application. It also allows jobs to
be created even when Sidekiq/Redis is temporarily unavailable. The separate
publisher process handles retries and ensure that each job is delivered to Sidekiq.

> :warning: Not all jobs are staged in Postgres. This is determined dynamically:
> if the job is enqueued from within an `ActiveRecord` transaction, then it is
> staged in Postgres. If not, then it bypasses Postgres and is enqueued directly
> to Redis via Sidekiq. To opt out of this behavior configure with
> SidekiqPublisher.configure { |c| c.stage_to_database_outside_transaction = true }

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
* **metrics_reporter**: an optional object to record metrics. See below.
* **batch_size**: the maximum number of jobs that will be enqueued together to Sidekiq
* **job_retention_period**: the duration that published jobs will be kept in
  Postgres after they have been enqueued to Sidekiq

### Metrics Reporter

The metrics reporter that can be configured with an object that is expected to
respond to the following API:

```ruby
count(metric_name, count)
gauge(metric_name, count)
```

Metrics will be reported for:

- the number of jobs published in each batch
- the number of jobs purged

#### Unpublished Jobs

There is also a module that can be used to record a metric for the number of
unpublished jobs:

```ruby
SidekiqPublisher::ReportUnpublishedCount.call
```

It is recommended to call this method periodically using something like
cron or [clockwork](https://github.com/Rykian/clockwork).

## Instrumentation

Instrumentation of this library is implemented using
[ActiveSupport::Notifications](https://api.rubyonrails.org/classes/ActiveSupport/Notifications.html).

The support for the configurable [metrics_reporter](lib/sidekiq_publisher/metrics_reporter.rb) and
[exception_reporter](lib/sidekiq_publisher/exception_reporter.rb) options is implemented using
[ActiveSupport::Subscriber](https://api.rubyonrails.org/classes/ActiveSupport/Subscriber.html).

If an alternate integration is required for metrics or error reporting then it can be implemented using outside this
library based on these examples.

### Tracing

The instrumentation in the library also supports integration with application tracing products, such as
[Datadog APM](https://www.datadoghq.com/product/apm/).

There is an optional integration with Datadog APM that can be required:

```ruby
require "sidekiq_publisher/datadog_apm"
```

This file must be required in addition including the `sidekiq_publisher` gem or requiring `sidekiq_publisher`.

This integration covers all of the sections of the library that are instrumented and serves an
[example](lib/sidekiq_publisher/datadog_apm) for implementing trace reporting for other products outside this library.

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

To selectively roll out the `SidekiqPublisher`, the adapter can be overridden for
a specific job class:

```ruby
class MyJob < ApplicationJob
  self.queue_adapter = :sidekiq_publisher
end
```

#### ActiveJob Exception Reporting

Many exception monitoring service (e.g. Sentry, Airbrake, Honeybadger, etc) already provide basic integration support for `Sidekiq`.
These integration should also work with `SidekiqPublisher`.
However, you may need to explicitly include
`ActiveJob::QueueAdapters::SidekiqPublisherAdapter` as a compatible adapter for this to work properly.

Alternatively, you can manually report the exception:

 ```ruby
retry_on SomeError, attempts: 10 do |_job, exception|
  Raven.capture_exception(exception, extra: { custom: :foo }) # Reporting using the Sentry gem
end
```

### SidekiqPublisher::Worker

Sidekiq workers are usually defined by including `Sidekiq::Job` or
`Sidekiq::Worker` in a class.

To use the `SidekiqPublisher`, this can be replaced by including
`SidekiqPublisher::Worker`. The usual `perform_async`, etc methods will be
available on the class but jobs will be staged in the Postgres table.

### Tying to a transaction
To guarantee that your job is enqueued when there's a change to the
system of record, simply publish it during the transaction
representing that change. Usually, that can be accomplished by
publishing in one of the ActiveRecord callbacks that are called
within-transaction (e.g. `after_save`, but not `after_commit` and its
derivatives):

```ruby
class Frob < ApplicationRecord
  after_save do
    MyJob.perform_later id
  end
end
```

For considering more complicated situations (e.g. jobs that should be
guaranteed during specific changes across models), the rails guides on
[querying](https://guides.rubyonrails.org/active_record_querying.html)
and
[callbacks](https://guides.rubyonrails.org/active_record_callbacks.html),
and the documentation on
[transactions](https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html)
in ActiveRecord are good resources to consult.

### Running

The publisher process that pulls the job data from Postgres and puts them into Redis
can be run with a rake task that is added via Railtie for Rails applications:

```bash
bundle exec rake sidekiq_publisher:publish
```

## Testing

### Sidekiq

When using sidekiq_publisher directly with Sidekiq workers, the testing modes
provided by Sidekiq are supported.

Require the `sidekiq_publisher/testing` file. (This should only be done in test!)

```ruby
require "sidekiq_publisher/testing"
```

This file requires "sidekiq/testing" so there is no need to explictly require both.
Note that by default, Sidekiq sets the test mode to `fake` and stores jobs in a
`jobs` array for each worker class.

To have `SidekiqPublisher` continue to insert jobs into a table within tests
call `Sidekiq::Testing.disable!`.

### ActiveJob

When using the sidekiq_publisher adapter for `ActiveJob`, use the `ActiveJob`
test adapter if you want to run jobs inline during tests.

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
https://github.com/ezcater/sidekiq_publisher.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
