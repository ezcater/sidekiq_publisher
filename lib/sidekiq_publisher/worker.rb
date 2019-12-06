# frozen_string_literal: true

module SidekiqPublisher
  module Worker
    def self.included(base)
      base.include(Sidekiq::Worker)
      base.singleton_class.public_send(:alias_method, :sidekiq_client_push, :client_push)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def client_push(item)
        SidekiqPublisher::Job.create_job!(item)
      end
    end
  end
end
