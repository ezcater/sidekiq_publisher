# frozen_string_literal: true

require "private_attr"
require "sidekiq_publisher/version"
require "sidekiq_publisher/job"
require "sidekiq_publisher/worker"
require "sidekiq_publisher/publisher"

module SidekiqPublisher
  DEFAULT_BATCH_SIZE = 100
  DEFAULT_JOB_RETENTION_PERIOD = 1.day.freeze

  class << self
    attr_accessor :logger, :exception_reporter
    attr_writer :batch_size, :job_retention_period

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
    end
  end
end
