# frozen_string_literal: true

require "active_record"

module SidekiqPublisher
  class Job < ActiveRecord::Base
    self.table_name = "sidekiq_publisher_jobs"

    before_create :ensure_job_id
    before_save :ensure_string_job_class

    validates :job_class, presence: true
    validates :args, exclusion: { in: [nil] }

    def self.generate_sidekiq_jid
      SecureRandom.hex(12)
    end

    # TODO: this method was just for testing and may be removed
    def publish
      Sidekiq::Client.push(sidekiq_item)
    end

    def sidekiq_item
      {
        "jid" => job_id,
        "class" => job_class.constantize,
        "args" => args,
        "at" => run_at,
        "queue" => queue,
        "wrapped" => wrapped,
      }.tap(&:compact!)
    end

    private

    def ensure_job_id
      self.job_id ||= self.class.generate_sidekiq_jid
    end

    def ensure_string_job_class
      self.job_class = job_class.to_s
    end
  end
end
