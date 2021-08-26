# frozen_string_literal: true

module SidekiqPublisher
  module Compatibility
    class << self
      # Sidekiq::Worker will be renamed to Sidekiq::Job in sidekiq 7.0.0 and a
      # deprecation warning will be printed in sidekiq 6.4.0, per
      # mperham/sidekiq#4971. Sidekiq 6.2.2 (mperham/sidekiq@8e36432) introduces
      # an alias and 6.3.0 includes it when the gem is loaded. This alias is
      # used here to ensure future compatibility.
      def sidekiq_job_class
        @_sidekiq_job_class ||= Gem::Dependency.new("sidekiq", ">= 6.3.0").then do |dependency|
          if dependency.match?(Gem.loaded_specs["sidekiq"])
            Sidekiq::Job
          else
            Sidekiq::Worker
          end
        end
      end
    end
  end
end
