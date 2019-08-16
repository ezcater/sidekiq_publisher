# frozen_string_literal: true

module SidekiqPublisher
  module ReportUnpublishedCount
    def self.call
      SidekiqPublisher.metrics_reporter.
        gauge("sidekiq_publisher.unpublished_count",
              SidekiqPublisher::Job.unpublished.count)
    end
  end
end
