# frozen_string_literal: true

module SidekiqPublisher
  module Worker
    def self.included(base)
      base.include(SidekiqPublisher::Compatibility.sidekiq_job_class)
      base.singleton_class.public_send(:alias_method, :sidekiq_client_push, :client_push)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def client_push(item)
        if SidekiqPublisher::DatabaseConnection.transaction_open?
          SidekiqPublisher::Job.create_job!(item).job_id
        else
          super
        end
      end
    end
  end
end
