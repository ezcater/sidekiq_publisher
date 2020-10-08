# frozen_string_literal: true

require "active_record"
require "pg"

module SidekiqPublisher
  module ReportUnpublishedCount
    def self.call(instrumenter: Instrumenter.new)
      instrumenter.instrument("unpublished.reporter",
                              unpublished_count: SidekiqPublisher::Job.unpublished.count)
    rescue ActiveRecord::StatementInvalid, PG::UnableToSend, PG::ConnectionBad => e
      cause = e.is_a?(ActiveRecord::StatementInvalid) ? e.cause : e
      ActiveRecord::Base.clear_active_connections! if cause.is_a?(PG::UnableToSend) || cause.is_a?(PG::ConnectionBad)
      raise
    end
  end
end
