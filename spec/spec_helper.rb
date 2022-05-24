# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../app/models", __dir__)
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "simplecov"
SimpleCov.start

require "active_record"
require "sidekiq_publisher/job"

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

Sidekiq.configure_client do |config|
  config.redis = {
    namespace: "sidekiq_publisher_test",
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379"),
  }
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

  pg = {
    database: ENV.fetch("POSTGRES_DATABASE", "sidekiq_publisher_test"),
    host: ENV.fetch("POSTGRES_HOST", "localhost"),
    port: ENV.fetch("POSTGRES_PORT", 5432),
    username: ENV.fetch("POSTGRES_USER", "ezcater"),
    password: ENV.fetch("POSTGRES_PASSWORD", "password"),
  }.freeze

  config.before(:suite) do
    pw_env = "PGPASSWORD=#{pg[:password]}"
    opts = "-h #{pg[:host]} -p #{pg[:port]} -U #{pg[:username]}"

    pg_version = `#{pw_env} psql #{opts} -t -c "select version()";`.strip
    puts "Testing with Postgres version: #{pg_version}"
    puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"

    `#{pw_env} dropdb #{opts} --if-exists #{pg[:database]} 2> /dev/null`
    `#{pw_env} createdb #{opts} #{pg[:database]}`

    puts "Using database postgres://#{pg[:host]}:#{pg[:port]}/#{pg[:database]}"

    ActiveRecord::Base.establish_connection(pg.merge(adapter: "postgresql"))
    ActiveRecord::Migration.verbose = false
    require "#{__dir__}/db/schema"
  end

  config.after(:suite) do
    ActiveRecord::Base.clear_all_connections!
    opts = "-h #{pg[:host]} -p #{pg[:port]} -U #{pg[:username]}"
    `PGPASSWORD=#{pg[:password]} dropdb #{opts} --if-exists #{pg[:database]}`
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
