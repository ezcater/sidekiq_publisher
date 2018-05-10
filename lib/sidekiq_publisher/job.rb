module SidekiqPublisher
  class Job < ApplicationJob #???
    self.table_name = "sidekiq_publisher_jobs".freeze
  end
end
