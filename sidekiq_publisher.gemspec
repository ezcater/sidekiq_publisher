# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
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

  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end
  # rubocop:enable Style/GuardClause

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

  spec.add_development_dependency "activejob"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "ezcater_rubocop", "~> 0.52.6"
  spec.add_development_dependency "overcommit"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "rspec_junit_formatter", "0.2.2"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "simplecov"

  spec.add_runtime_dependency "activerecord-postgres_pub_sub"
  spec.add_runtime_dependency "sidekiq"
end
