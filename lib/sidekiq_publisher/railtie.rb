# frozen_string_literal: true

module SidekiqPublisher
  class Railtie < Rails::Railtie
    rake_tasks do
      load "sidekiq_publisher/tasks.rake"
    end

    initializer "sidekiq_publisher.configure" do
      SidekiqPublisher.logger = Rails.logger
    end
  end
end
