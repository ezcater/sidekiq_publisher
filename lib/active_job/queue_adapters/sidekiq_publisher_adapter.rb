# frozen_string_literal: true

require "active_job/queue_adapters/sidekiq_adapter"

module ActiveJob
  module QueueAdapters
    # To use SidekiqPublisher set the queue_adapter config to +:sidekiq_publisher+.
    #   Rails.application.config.active_job.queue_adapter = :sidekiq_publisher
    class SidekiqPublisherAdapter
      JOB_WRAPPER_CLASS = ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.to_s.freeze

      def enqueue(job)
        internal_enqueue(job)
      end

      def enqueue_at(job, timestamp)
        internal_enqueue(job, timestamp)
      end

      private

      def internal_enqueue(job, timestamp = nil)
        job.provider_job_id = SidekiqPublisher::Job.generate_sidekiq_jid
        attributes = job_attributes(job)
        attributes[:run_at] = timestamp if timestamp.present?
        SidekiqPublisher::Job.create!(attributes).job_id
      end

      def job_attributes(job)
        {
          job_id: job.provider_job_id,
          job_class: JOB_WRAPPER_CLASS,
          wrapped: job.class.to_s,
          queue: job.queue_name,
          args: [job.serialize],
        }
      end
    end
  end
end
