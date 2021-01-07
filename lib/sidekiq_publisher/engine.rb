# frozen_string_literal: true

module SidekiqPublisher
  class Engine < Rails::Engine
    isolate_namespace SidekiqPublisher

    initializer "sidekiq_publisher.configure" do
      SidekiqPublisher.logger = Rails.logger
    end
  end
end
