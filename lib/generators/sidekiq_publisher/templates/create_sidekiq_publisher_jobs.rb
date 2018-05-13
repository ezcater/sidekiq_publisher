# frozen_string_literal: true

class CreateSidekiqPublisherJobs < ActiveRecord::Migration[5.1]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table(:sidekiq_publisher_jobs, id: :bigserial) do |t|
      t.string :job_id, null: false
      t.string :job_class, null: false
      t.string :queue
      t.string :wrapped
      t.json :args, null: false
      t.float :run_at
      t.timestamp :published_at
      t.timestamp :created_at, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    add_index(:sidekiq_publisher_jobs, :published_at)
  end
end
