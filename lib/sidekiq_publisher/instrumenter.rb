# frozen_string_literal: true

module SidekiqPublisher
  class Instrumenter
    NAMESPACE = "sidekiq_publisher"

    def initialize
      @backend = if defined?(ActiveSupport::Notifications)
                   ActiveSupport::Notifications
                 end
    end

    def instrument(event_name, payload = {}, &block)
      if backend
        backend.instrument("#{event_name}.#{NAMESPACE}", payload, &block)
      else
        yield(payload) if block
      end
    end

    private

    attr_reader :backend
  end
end
