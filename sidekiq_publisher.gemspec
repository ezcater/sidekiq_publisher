# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq_publisher/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_publisher"
  spec.version       = SidekiqPublisher::VERSION
  spec.authors       = ["ezCater, Inc"]
  spec.email         = ["engineering@ezcater.com"]
  spec.summary       = "Publisher for enqueuing jobs to Sidekiq"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/ezcater/sidekiq_publisher"
  spec.license       = "MIT"

  # Set "allowed_push_post" to control where this gem can be published.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
    spec.metadata["rubygems_mfa_required"] = "true"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  excluded_files = %w(.circleci/config.yml
                      .github/PULL_REQUEST_TEMPLATE.md
                      .gitignore
                      .rspec
                      .rubocop.yml
                      .ruby-gemset
                      .ruby-version
                      .travis.yml
                      bin/console
                      bin/setup
                      Rakefile)

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(/^(test|spec|features)\//)
  end - excluded_files
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6"

  spec.add_development_dependency "activejob"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "ddtrace", ">= 1.8.0"
  spec.add_development_dependency "ezcater_matchers"
  spec.add_development_dependency "ezcater_rubocop", ">= 3.0.2", "< 4.0"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "overcommit"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redis-namespace"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "rspec_junit_formatter", "0.2.2"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "simplecov", "< 0.18"

  spec.add_runtime_dependency "activerecord", ">= 6.1", "< 7.2"
  spec.add_runtime_dependency "activerecord-postgres_pub_sub", ">= 0.4.0"
  spec.add_runtime_dependency "activesupport", ">= 6.1", "< 7.2"
  spec.add_runtime_dependency "sidekiq", ">= 6.4.1", "< 7"
end
