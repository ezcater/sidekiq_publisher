ActiveRecord::Schema.define do
  TABLE_NAME = "sidekiq_publisher_jobs".freeze
  NOTIFICATION_NAME = "sidekiq_publisher_job".freeze
  TABLE_MODULE = "sidekiq_publisher".freeze

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

  add_index(:sidekiq_publisher_jobs, :published_at)

  execute <<-SQL
    CREATE OR REPLACE FUNCTION notify_#{TABLE_MODULE}_listeners() RETURNS TRIGGER AS $$
    DECLARE
    BEGIN
      PERFORM pg_notify('#{NOTIFICATION_NAME}', null);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
  SQL

  execute <<-SQL
    CREATE TRIGGER #{TABLE_MODULE}_trigger
    AFTER INSERT
    ON #{TABLE_NAME}
    FOR EACH STATEMENT
    EXECUTE PROCEDURE notify_#{TABLE_MODULE}_listeners()
  SQL
end
