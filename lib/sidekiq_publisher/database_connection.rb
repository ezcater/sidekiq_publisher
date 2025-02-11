# frozen_string_literal: true

module SidekiqPublisher
  module DatabaseConnection
    # TODO: this is deprecated and should not be used outside if this class
    def self.transaction_open?
      ActiveRecord::Base.connection.transaction_open?
    end

    def self.should_stage_to_database?
      SidekiqPublisher.stage_to_database_outside_transaction || transaction_open?
    end
  end
end
