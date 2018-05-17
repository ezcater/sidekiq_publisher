# frozen_string_literal: true

require "active_record"

module SidekiqPublisher
  class Job < ActiveRecord::Base
    self.table_name = "sidekiq_publisher_jobs"

    BATCH_KEYS = %i(id job_id job_class args run_at queue wrapped created_at).freeze

    before_create :ensure_job_id
    before_save :ensure_string_job_class

    validates :job_class, presence: true
    validates :args, exclusion: { in: [nil] }

    scope :unpublished, -> { where(published_at: nil) }
    scope :published, -> { where.not(published_at: nil) }
    scope :purgeable, -> { where("published_at < ?", Time.now.utc - job_retention_period) }

    def self.generate_sidekiq_jid
      SecureRandom.hex(12)
    end

    def self.job_retention_period
      SidekiqPublisher.job_retention_period
    end

    def self.published!(ids)
      where(id: ids).update_all(published_at: Time.now.utc)
    end

    def self.purge_expired_published!
      SidekiqPublisher.logger.info("#{name} purging expired published jobs.")
      count = purgeable.delete_all
      SidekiqPublisher.logger.info("#{name} purged #{count} expired published jobs.")
    end

    def self.unpublished_batches(batch_size: SidekiqPublisher.batch_size)
      unpublished.in_batches(of: batch_size, load: false) do |relation|
        batch = relation.pluck(*BATCH_KEYS)
        yield batch.map { |values| Hash[BATCH_KEYS.zip(values)] }
      end
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
