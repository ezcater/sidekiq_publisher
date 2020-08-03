# frozen_string_literal: true

require "active_support/notifications"

module SidekiqPublisher
  class Instrumenter
    NAMESPACE = "sidekiq_publisher"

    def instrument(event_name, payload = {}, &block)
      ActiveSupport::Notifications.instrument("#{event_name}.#{NAMESPACE}", payload, &block)
    end
  end
end
