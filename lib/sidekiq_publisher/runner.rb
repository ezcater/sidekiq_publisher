# frozen_string_literal: true

require "activerecord-postgres_pub_sub"

module SidekiqPublisher
  class Runner
    LISTENER_TIMEOUT_SECONDS = 60
    CHANNEL_NAME = "sidekiq_publisher_job"

    def self.run(instrumenter = Instrumenter.new)
      new(instrumenter).run
    end

    def initialize(instrumenter = Instrumenter.new)
      @instrumenter = instrumenter
      @publisher = Publisher.new(instrumenter: @instrumenter)
    end

    def run
      ActiveRecord::PostgresPubSub::Listener.listen(
        CHANNEL_NAME,
        listen_timeout: LISTENER_TIMEOUT_SECONDS
      ) do |listener|
        listener.on_start { call_publish("start") }
        listener.on_notify { call_publish("notify") }
        listener.on_timeout { listener_timeout }
      end
    end

    private

    attr_reader :publisher, :instrumenter

    def call_publish(event)
      instrumenter.instrument("#{event}.publisher") do
        publisher.publish
      end
    end

    def listener_timeout
      instrumenter.instrument("timeout.listener") do
        if Job.unpublished.exists?
          SidekiqPublisher.logger&.warn(
            "#{self.class.name}: msg='publishing pending jobs at timeout'"
          )
          call_publish("timeout")
        else
          Job.purge_expired_published!(instrumenter: instrumenter)
        end
      end
    end
  end
end
