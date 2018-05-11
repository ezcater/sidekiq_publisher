require "active_record"

module SidekiqPublisher
  class Job < ActiveRecord::Base
    self.table_name = "sidekiq_publisher_jobs".freeze
  end
end
