# frozen_string_literal: true

require "activerecord-postgres_pub_sub"

module SidekiqPublisher
  class Runner
    LISTENER_TIMEOUT_SECONDS = 60
    CHANNEL_NAME = "sidekiq_publisher_job"

    def self.run
      new.run
    end

    def initialize
      @publisher = Publisher.new
    end

    def run
      ActiveRecord::PostgresPubSub::Listener.listen(
        CHANNEL_NAME,
        listen_timeout: LISTENER_TIMEOUT_SECONDS
      ) do |listener|
        listener.on_start { publisher.publish }
        listener.on_notify { publisher.publish }
        listener.on_timeout { listener_timeout }
      end
    end

    private

    attr_reader :publisher

    def listener_timeout
      if Job.unpublished.exists?
        SidekiqPublisher.logger&.warn(
          "#{self.class.name}: msg='publishing pending jobs at timeout'"
        )
        publisher.publish
      else
        Job.purge_expired_published!
      end
    end
  end
end
