# frozen_string_literal: true

require "sidekiq_publisher/client"

module SidekiqPublisher
  class Publisher
    extend PrivateAttr

    private_attr_reader :client

    def initialize
      @client = SidekiqPublisher::Client.new
    end

    def publish
      Job.unpublished_batches(batch_size: batch_size) do |batch|
        items = batch.map do |job|
          {
            "jid" => job[:job_id],
            "class" => job[:job_class].constantize,
            "args" => job[:args],
            "at" => job[:run_at],
            "queue" => job[:queue],
            "wrapped" => job[:wrapped],
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
      count = client.bulk_push(items)
      update_jobs_as_published!(batch)
    rescue StandardError => ex
      failure_warning(__method__, ex)
    ensure
      update_jobs_as_published!(batch) if count.present?
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
  end
end
