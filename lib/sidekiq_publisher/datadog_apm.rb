# frozen_string_literal: true

require "active_support/subscriber"
require "ddtrace"

module SidekiqPublisher
  module DatadogAPM
    class << self
      attr_writer :service

      def service
        @service || "sidekiq-publisher"
      end
    end

    class Subscriber
      def self.subscribe_to(pattern)
        ActiveSupport::Notifications.subscribe(pattern, new)
      end

      def finish(_name, _id, payload)
        finish_span(payload)
      end

      private

      def start_span(operation, payload)
        # Internal sanity check
        raise "Fix operation name: #{operation}" if operation.end_with?("sidekiq_publisher")

        payload[:datadog_span] = Datadog.tracer.trace(operation, service: service)
      end

      def finish_span(payload)
        payload[:datadog_span]&.set_error(payload[:exception_object]) if payload.key?(:exception_object)
        payload[:datadog_span]&.finish
      end

      def service
        SidekiqPublisher::DatadogAPM.service
      end
    end

    class ListenerSubscriber < Subscriber
      def start(_name, _id, payload)
        start_span("listener.timeout", payload)
      end

      subscribe_to "timeout.listener.sidekiq_publisher"
    end

    class RunnerSubscriber < Subscriber
      def start(name, _id, payload)
        op_name = name.split(".").first
        start_span("publisher.#{op_name}", payload)
      end

      subscribe_to "start.publisher.sidekiq_publisher"
      subscribe_to "notify.publisher.sidekiq_publisher"
      subscribe_to "timeout.publisher.sidekiq_publisher"
    end

    class PublisherSubscriber < Subscriber
      def start(name, _id, payload)
        op_name = name.split(".").first
        start_span("publisher.#{op_name}", payload)
      end

      def finish(name, id, payload)
        payload[:datadog_span]&.set_tag(:published_count, payload[:published_count]) if payload.key?(:published_count)
        super
      end

      subscribe_to "publish_batch.publisher.sidekiq_publisher"
      subscribe_to "enqueue_batch.publisher.sidekiq_publisher"
    end

    class JobSubscriber < Subscriber
      def start(_name, _id, payload)
        start_span("job.purge", payload)
      end

      def finish(_name, _id, payload)
        payload[:datadog_span]&.set_tag(:purged_count, payload[:purged_count]) if payload.key?(:purged_count)

        super
      end

      subscribe_to "purge.job.sidekiq_publisher"
    end

    # This subscriber is different from the classes above because it is an ActiveSupport::Subscriber
    # and responds to the error(.publisher.sidekiq_publisher) event.
    class PublisherErrorSubscriber < ActiveSupport::Subscriber
      def error(event)
        Datadog.tracer.active_span&.set_error(event.payload[:exception_object])
      end

      attach_to "publisher.sidekiq_publisher"
    end
  end
end
