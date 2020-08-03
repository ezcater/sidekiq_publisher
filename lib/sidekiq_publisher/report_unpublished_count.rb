# frozen_string_literal: true

module SidekiqPublisher
  module ReportUnpublishedCount
    def self.call(instrumenter: Instrumenter.new)
      instrumenter.instrument("unpublished.reporter",
                              unpublished_count: SidekiqPublisher::Job.unpublished.count)
    end
  end
end
