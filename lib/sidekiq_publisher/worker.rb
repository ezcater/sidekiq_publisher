# frozen_string_literal: true

module SidekiqPublisher
  module Worker
    def self.included(base)
      base.include(Sidekiq::Worker)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def client_push(item)
        SidekiqPublisher::Job.create!(
          job_class: item["class"].to_s,
          args: item["args"],
          run_at: item["at"],
          queue: item["queue"]
        )
      end
    end
  end
end
