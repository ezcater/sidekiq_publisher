# frozen_string_literal: true

require "sidekiq_publisher"
require "sidekiq/testing"

module SidekiqPublisher
  module Testing
    def self.prepended(base)
      base.singleton_class.public_send(:alias_method, :original_create_job!, :create_job!)
      base.singleton_class.prepend(ClassMethods)
    end

    module ClassMethods
      def create_job!(item)
        if Sidekiq::Testing.enabled?
          item["class"].sidekiq_client_push(item)
        else
          original_create_job!(item)
        end
      end
    end
  end
end

SidekiqPublisher::Job.prepend(SidekiqPublisher::Testing)
