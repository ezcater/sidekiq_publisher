# frozen_string_literal: true

require "active_support/subscriber"

module SidekiqPublisher
  module MetricsReporter
    class Subscriber < ActiveSupport::Subscriber
      private

      def count(metric, value)
        SidekiqPublisher.metrics_reporter&.try(:count, metric, value) unless value.nil?
      end
    end

    class PublisherSubscriber < Subscriber
      def enqueue_batch(event)
        count("sidekiq_publisher.published", event.payload[:published_count])
      end

      attach_to "publisher.sidekiq_publisher"
    end

    class JobSubscriber < Subscriber
      def purge(event)
        count("sidekiq_publisher.purged", event.payload[:purged_count])
      end

      attach_to "job.sidekiq_publisher"
    end

    class UnpublishedSubscriber < Subscriber
      def unpublished(event)
        SidekiqPublisher.metrics_reporter&.
          try(:gauge, "sidekiq_publisher.unpublished_count", event.payload[:unpublished_count])
      end

      attach_to "reporter.sidekiq_publisher"
    end
  end
end
