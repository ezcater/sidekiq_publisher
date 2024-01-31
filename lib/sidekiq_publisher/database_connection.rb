# frozen_string_literal: true

module SidekiqPublisher
  module DatabaseConnection
    def self.transaction_open?
      ActiveRecord::Base.connection.transaction_open?
    end
  end
end
