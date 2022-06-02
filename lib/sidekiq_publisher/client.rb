# frozen_string_literal: true

require "sidekiq"

module SidekiqPublisher
  class Client < Sidekiq::Client
    def bulk_push(items)
      payloads = items.map do |item|
        normed = normalize_item(item)
        middleware.invoke(item["class"], normed, normed["queue"], @redis_pool) { normed } || nil
      end.compact

      pushed = 0
      with_connection do |conn|
        conn.multi do |transaction|
          payloads.each do |payload|
            atomic_push(transaction, [payload])
            pushed += 1
          end
        end
      end

      pushed
    end

    private

    def with_connection(&blk)
      @redis_pool.with(&blk)
    end
  end
end
