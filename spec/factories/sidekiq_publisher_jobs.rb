# frozen_string_literal: true

FactoryBot.define do
  factory :sidekiq_publisher_job,
          class: SidekiqPublisher::Job,
          aliases: %i(publisher_job unpublished_job) do

    job_id { SidekiqPublisher::Job.generate_sidekiq_jid }
    job_class "TestJobClass"
    sequence(:args) { |n| Hash[x: n] }

    factory :old_unpublished_job do
      created_at { Time.now.utc - SidekiqPublisher.job_retention_period - 1 }
    end

    factory :published_job do
      published_at { Time.now.utc }

      factory :purgeable_job do
        published_at { Time.now.utc - SidekiqPublisher.job_retention_period - 1 }
        created_at { published_at }
      end
    end
  end
end
