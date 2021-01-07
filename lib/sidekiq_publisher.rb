# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/numeric/time"
require "sidekiq_publisher/version"
require "sidekiq_publisher/instrumenter"
require "sidekiq_publisher/metrics_reporter"
require "sidekiq_publisher/exception_reporter"
require "sidekiq_publisher/report_unpublished_count"
require "sidekiq_publisher/worker"
require "sidekiq_publisher/publisher"
require "sidekiq_publisher/runner"
require "sidekiq_publisher/engine" if defined?(Rails)

module SidekiqPublisher
  DEFAULT_BATCH_SIZE = 100
  DEFAULT_JOB_RETENTION_PERIOD = 1.day.freeze

  class << self
    attr_accessor :logger, :exception_reporter, :metrics_reporter
    attr_writer :batch_size, :job_retention_period

    def configure
      yield self
    end

    def batch_size
      @batch_size || DEFAULT_BATCH_SIZE
    end

    def job_retention_period
      @job_retention_period || DEFAULT_JOB_RETENTION_PERIOD
    end

    # For test purposes
    def reset!
      @batch_size = nil
      @job_retention_period = nil
      @exception_reporter = nil
      @metrics_reporter = nil
    end
  end
end
