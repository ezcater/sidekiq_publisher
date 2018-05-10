require "activerecord-import"

module ActiveJob
  module QueueAdapters
    # TODO: document
    # To use SidekiqPublisher set the queue_adapter config to +:sidekiq_publisher+.
    #   Rails.application.config.active_job.queue_adapter = :sidekiq_publisher
    class SidekiqPublisherAdapter
      def enqueue(job)
        attributes = job_attributes(job)
        SidekiqPublisher::Job.import(attributes, validate: false)
        job.provider_job_id = attributes[job_id]
      end

      def enqueue_at(job, timestamp)
        attributes = job_attributes(job).merge!(enqueue_at: timestamp)
        SidekiqPublisher::Job.import(attributes, validate: false)
        job.provider_job_id = attributes[job_id]
      end

      private

      def job_attributes(job)
        {
          job_id: SecureRandom.hex(12),
          job_class: job.class.to_s,
          queue: job.queue_name,
          args: [job.serialize],
        }
      end
    end
  end
end
