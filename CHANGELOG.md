# sidekiq_publisher

## 5.1.0
- Add stage_to_database_outside_transaction configuration option

## 5.0.0
- BREAKING: Drop support for Sidekiq < 6.1.
- Add support for ActiveSupport and ActiveJob 7.1

## 4.0.0
- BREAKING: Enqueue directly to Redis unless in a transaction ([#74](https://github.com/ezcater/sidekiq_publisher/pull/74/))

## 3.0.0
- BREAKING: Drop support for Ruby `2.6` and `2.7` as they are [past end of life](https://endoflife.date/ruby)
- BREAKING: Drop support for `ddtrace <= 1.8.0`
- BREAKING: Drop support for Redis `5.x`
- (internal) Move CI to Github workflows

## 2.4.0
- Update active_support dependency to allow any active_support 7.x.x version

## 2.3.0
- Add support for ddtrace 1.x.
- Add support for sidekiq 6.4.2+.

## 2.2.0
- Add support for redis 5.0.0 by replacing pipelined commands.
  - Also resolves deprecation warnings introduced in [redis 4.6.0]

[redis 4.6.0]: https://github.com/redis/redis-rb/blob/master/CHANGELOG.md#460

- Restricts sidekiq to < 6.4.2 due to an incompatability
  - [issue tracking this](https://github.com/ezcater/sidekiq_publisher/issues/55)

- Restricts ddtrace to < 1.0.0 due to an incompatability

## 2.1.1
- Opt-in to [Rubygems MFA](https://guides.rubygems.org/mfa-requirement-opt-in/)
  for privileged operations

## 2.1.0
- Add support for sidekiq `7.0.0` by using `Sidekiq::Job` instead of
  `Sidekiq::Worker` in sidekiq `>= 6.3.0` to handle name changes outlined in
  mperham/sidekiq#4971 and first introduced in 6.2.2.

## 2.0.1
- Changing the `Job#args` validator to be a manual check instead of using the `exclusions` validator.  This is to fix an issue introduced with rails 6.1 and the condition of `in: [nil]`.  More details [here](https://github.com/rails/rails/issues/41051).

## v2.0.0
- Transition from defining a Railtie to becoming a Rails Engine
  [(#44)](https://github.com/ezcater/sidekiq_publisher/pull/44). This change was
  made to better support Ruby 3.0 and Rails 6.1. The change is *not* expected to
  be breaking but it does represent a major change in the gem's implementation
  and that is the reason for the major version bump.
- Require Ruby 2.6 or later.

## v1.8.0
- Extend support to Rails 6.1.

## v1.7.1
- Gracefully handle database connection errors in ReportUnpublishedCount by attempting to reconnect.

## v1.7.0
- Add instrumentation using `ActiveSupport::Notifications`.
- Reimplement `metrics_reporter` and `exception_reporter` support using
  `ActiveSupport::Subscriber`.
- Add optional integration with Datadog APM.

## v1.6.4
- Expand sidekiq support to v5.0.x-v6.x.x.

## v1.6.3
- Handle client middleware that returns false.

## v1.6.2
- Gracefully respond to `INT` and `TERM` process signals.

## v1.6.1
- Remove the `private_attr` top-level gem dependency.

## v1.6.0
- Support `Sidekiq::Testing` modes. This only applies to `SidekiqPublisher::Worker`
  and not the `ActiveJob` adapter.

## v1.5.0
- Expand sidekiq support to v5.0.x-v6.0.x.

## v1.4.0
- Preserve access to `Sidekiq::Worker`'s `.client_push` method.

## v1.3.0
- Extend support to Rails 6.0.

## v1.2.0
- Add `ReportUnpublishedCount` to record a metric for the number
  of unpublished jobs.

## v1.1.0
- Expand sidekiq support to v5.0.x-v5.2.x.

## v1.0.0
- No change.

## v0.3.3
- Do not report published count metric if it is nil.

## v0.3.2
- Require `activerecord-postgres_pub_sub` v0.4.0 or later for
  strong migrations support.

## v0.3.1
- Index published_at as part of create table.

## v0.3.0
- Add support for Rails 5.2.

## v0.2.1
- Use period instead of colon as a separator in metric names.

## v0.2.0
- Add caching for job class constant lookup.
- Add metrics for the number of jobs published and purged.
- Add ActiveSupport as a runtime dependency.

## v0.1.1
- Publish Sidekiq jobs with the `created_at` value from when the job was inserted
  into the table.

## v0.1.0
- Initial version
