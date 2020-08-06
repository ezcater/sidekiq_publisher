# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "simplecov"
SimpleCov.start

require "active_support/notifications"
require "sidekiq_publisher/datadog_apm"

require "active_job"
require "sidekiq_publisher/testing"
require "active_job/queue_adapters/sidekiq_publisher_adapter"

require "database_cleaner"
require "factory_bot"
require "shoulda-matchers"
require "ezcater_matchers"

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

logger = Logger.new("log/test.log", level: :debug)
ActiveRecord::Base.logger = logger
SidekiqPublisher.logger = logger

Sidekiq::Testing.disable!

DATABASE_NAME = "sidekiq_publisher_test"
REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379")

Sidekiq.configure_client do |config|
  config.redis = { namespace: "sidekiq_publisher_test", url: REDIS_URL }
end

Datadog.configure do |c|
  c.tracer = Datadog::TestTracer.new
  c.env = "test"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before(:suite) do
    pg_version = `psql -t -c "select version()";`.strip
    puts "Testing with Postgres version: #{pg_version}"
    puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"

    `dropdb --if-exists #{DATABASE_NAME} 2> /dev/null`
    `createdb #{DATABASE_NAME}`

    host = ENV.fetch("PGHOST", "localhost")
    port = ENV.fetch("PGPORT", 5432)
    database_url = "postgres://#{host}:#{port}/#{DATABASE_NAME}"
    puts "Using database #{database_url}"
    ActiveRecord::Base.establish_connection(database_url)
    ActiveRecord::Migration.verbose = false
    require "#{__dir__}/db/schema"
  end

  config.after(:suite) do
    ActiveRecord::Base.clear_all_connections!
    `dropdb --if-exists #{DATABASE_NAME}`
  end

  config.before do
    SidekiqPublisher.reset!
  end

  config.before do |example|
    unless example.metadata.fetch(:skip_db_clean, false)
      DatabaseCleaner.strategy = example.metadata.fetch(:cleaner_strategy, :transaction)
      DatabaseCleaner.start
    end
  end

  config.after do |example|
    DatabaseCleaner.clean unless example.metadata.fetch(:skip_db_clean, false)
  end

  config.after { Datadog.tracer.reset! }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_model
    with.library :active_record
  end
end
