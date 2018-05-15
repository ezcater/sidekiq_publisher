# frozen_string_literal: true

namespace :sidekiq_publisher do
  task publish: [:environment] do
    SidekiqPublisher::Runner.run
  end
end
