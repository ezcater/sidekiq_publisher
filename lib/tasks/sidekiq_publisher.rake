# frozen_string_literal: true

namespace :sidekiq_publisher do
  desc "Start the Sidekiq Publisher runner"
  task publish: [:environment] do
    Signal.trap("INT") { exit(0) }
    Signal.trap("TERM") { exit(0) }

    SidekiqPublisher::Runner.run
  end
end
