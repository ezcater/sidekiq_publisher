# sidekiq_publisher

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
