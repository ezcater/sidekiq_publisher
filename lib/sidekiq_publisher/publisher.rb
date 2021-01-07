# frozen_string_literal: true

require "sidekiq_publisher/client"
require "active_support/core_ext/object/blank"

module SidekiqPublisher
  class Publisher
    def initialize(instrumenter: Instrumenter.new)
      @instrumenter = instrumenter
      @client = SidekiqPublisher::Client.new
      @job_class_cache = {}
    end

    def publish
      Job.unpublished_batches do |batch|
        instrumenter.instrument("publish_batch.publisher") do
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

          instrumenter.instrument("enqueue_batch.publisher") do |notification|
            enqueue_batch(batch, items, notification)
          end
        end
      end
      purge_expired_published_jobs
    rescue StandardError => ex
      failure_warning(__method__, ex)
    end

    private

    attr_reader :client, :job_class_cache, :instrumenter

    def enqueue_batch(batch, items, notification)
      pushed_count = client.bulk_push(items)
      published_count = update_jobs_as_published!(batch)
    rescue StandardError => ex
      failure_warning(__method__, ex)
    ensure
      published_count = update_jobs_as_published!(batch) if pushed_count.present? && published_count.nil?
      notification[:published_count] = published_count if published_count.present?
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
      Job.purge_expired_published!(instrumenter: instrumenter) if perform_purge?
    end

    def perform_purge?
      rand(100).zero?
    end

    def failure_warning(method, ex)
      logger.warn("#{self.class.name}: msg=\"#{method} failed\" error=#{ex.class} error_msg=#{ex.message.inspect}\n")
      instrumenter.instrument("error.publisher",
                              exception_object: ex, exception: [ex.class.name, ex.message])
    end

    def logger
      SidekiqPublisher.logger
    end
  end
end
