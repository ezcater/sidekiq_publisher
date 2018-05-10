require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module SidekiqPublisher
  class InstallGenerator < Rails::Generators::Base
    source_paths << File.join(__dir__, "templates")

    def create_migration_file
      migration_template("create_sidekiq_publisher_jobs.rb",
                         "db/migrate/create_sidekiq_publisher_jobs.rb")
    end
  end
end
