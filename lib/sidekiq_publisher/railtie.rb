# frozen_string_literal: true

module SidekiqPublisher
  class Railtie < Rails::Railtie
    rake_tasks do
      load "sidekiq_publisher/tasks.rake"
    end
  end
end
