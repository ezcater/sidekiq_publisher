# frozen_string_literal: true

require "active_support/subscriber"

module SidekiqPublisher
  module ExceptionReporter
    class PublisherErrorSubscriber < ActiveSupport::Subscriber
      def error(event)
        SidekiqPublisher.exception_reporter&.call(event.payload[:exception_object])
      end

      attach_to "publisher.sidekiq_publisher"
    end
  end
end
