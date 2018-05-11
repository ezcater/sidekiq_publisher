# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module SidekiqPublisher
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    TEMPLATE_FILE = "create_sidekiq_publisher_jobs.rb".freeze

    source_paths << File.join(__dir__, "templates")

    def create_migration_file
      migration_template(TEMPLATE_FILE, "db/migrate/#{TEMPLATE_FILE}")
    end

    def generate_notify_trigger
      invoke "active_record:postgres_pub_sub:notify_on_insert",
             [],
             model_name: "SidekiqPublisher::Job"
    end
  end
end
