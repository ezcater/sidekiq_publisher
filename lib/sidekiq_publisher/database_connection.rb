# frozen_string_literal: true

module SidekiqPublisher
  module DatabaseConnection
    def self.should_stage_to_database?
      SidekiqPublisher.stage_to_database_outside_transaction ||
        ActiveRecord::Base.connection.transaction_open?
    end
  end
end
