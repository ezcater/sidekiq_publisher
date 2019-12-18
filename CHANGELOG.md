# sidekiq_publisher

## v1.6.1 (unreleased)
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
