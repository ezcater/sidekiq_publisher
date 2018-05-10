class CreateSidekiqPublisherJobs < ActiveRecord::Migration[5.1]
  def up
    create_table(:sidekiq_publisher_jobs, id: :bigserial) do |t|
      t.string :job_id, null: false
      t.string :job_class, null: false
      t.string :queue, null: false
      t.json :args, null: false
      t.timestamp :enqueue_at
      t.timestamp :published_at
      t.timestamp :created_at, null: false
    end

    add_index(:sidekiq_publisher_jobs, :published_at)

    execute <<-SQL
      CREATE OR REPLACE FUNCTION notify_sidekiq_publisher_listener() RETURNS TRIGGER AS $$
      DECLARE
      BEGIN
        PERFORM pg_notify('sidekiq_publisher_job', null);
        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;
    SQL

    execute <<-SQL
      CREATE TRIGGER sidekiq_publisher_trigger
      AFTER INSERT
      ON sidekiq_publisher_jobs
      FOR EACH STATEMENT
      EXECUTE PROCEDURE notify_sidekiq_publisher_listener()
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION notify_sidekiq_publisher_listener() CASCADE
    SQL

    drop_table(:sidekiq_publisher_jobs)
  end
end
