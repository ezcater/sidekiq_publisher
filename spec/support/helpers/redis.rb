# frozen_string_literal: true

module RedisHelpers
  # This uses redis-namespace to scope by a namespace.
  # We should clear the keys like this rather than `flushdb`, which doesn't
  # respect the namespace (in case the user hasn't configured a different
  # Redis DB for these specs).
  def clear_redis
    Sidekiq.redis do |conn|
      conn.scan_each do |key|
        conn.del(key)
      end
    end
  end
end
