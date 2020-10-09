# frozen_string_literal: true

require "active_record"
require "pg"

module SidekiqPublisher
  module ReportUnpublishedCount
    def self.call(instrumenter: Instrumenter.new)
      instrumenter.instrument("unpublished.reporter",
                              unpublished_count: SidekiqPublisher::Job.unpublished.count)
    rescue ActiveRecord::StatementInvalid, PG::UnableToSend, PG::ConnectionBad => e
      ActiveRecord::Base.clear_active_connections! if db_connection_error?(e)
      raise
    end

    def self.db_connection_error?(error)
      cause = error.is_a?(ActiveRecord::StatementInvalid) ? error.cause : error
      cause.is_a?(PG::UnableToSend) || cause.is_a?(PG::ConnectionBad)
    end
    private_class_method :db_connection_error?
  end
end
