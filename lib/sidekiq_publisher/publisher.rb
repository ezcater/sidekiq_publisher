# frozen_string_literal: true

require "sidekiq_publisher/client"
require "active_support/core_ext/object/try"

module SidekiqPublisher
  class Publisher
    extend PrivateAttr

    private_attr_reader :client, :job_class_cache

    def initialize
      @client = SidekiqPublisher::Client.new
      @job_class_cache = {}
    end

    def publish
      Job.unpublished_batches do |batch|
        items = batch.map do |job|
          {
            "jid" => job[:job_id],
            "class" => lookup_job_class(job[:job_class]),
            "args" => job[:args],
            "at" => job[:run_at],
            "queue" => job[:queue],
            "wrapped" => job[:wrapped],
            "created_at" => job[:created_at].to_f,
          }.tap(&:compact!)
        end

        publish_batch(batch, items)
      end
      purge_expired_published_jobs
    rescue StandardError => ex
      failure_warning(__method__, ex)
    end

    private

    def publish_batch(batch, items)
      pushed_count = client.bulk_push(items)
      published_count = update_jobs_as_published!(batch)
    rescue StandardError => ex
      failure_warning(__method__, ex)
    ensure
      published_count = update_jobs_as_published!(batch) if pushed_count.present? && published_count.nil?
      metrics_reporter.try(:count, "sidekiq_publisher.published", published_count) if published_count.present?
    end

    def lookup_job_class(name)
      job_class_cache.fetch(name) do
        job_class_cache[name] = name.constantize
      end
    end

    def update_jobs_as_published!(jobs)
      Job.published!(jobs.map { |job| job[:id] })
    end

    def purge_expired_published_jobs
      Job.purge_expired_published! if perform_purge?
    end

    def perform_purge?
      rand(100).zero?
    end

    def failure_warning(method, ex)
      logger.warn("#{self.class.name}: msg=\"#{method} failed\" error=#{ex.class} error_msg=#{ex.message.inspect}\n"\
                  "#{ex.backtrace.join("\n")}")
      SidekiqPublisher.exception_reporter&.call(ex)
    end

    def logger
      SidekiqPublisher.logger
    end

    def metrics_reporter
      SidekiqPublisher.metrics_reporter
    end
  end
end
