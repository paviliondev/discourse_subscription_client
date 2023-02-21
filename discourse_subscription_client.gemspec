# frozen_string_literal: true

require_relative "lib/discourse_subscription_client/version"

Gem::Specification.new do |spec|
  spec.name        = "discourse_subscription_client"
  spec.version     = DiscourseSubscriptionClient::VERSION
  spec.authors     = ["Angus McLeod"]
  spec.email       = ["angus@mcleod.org.au"]
  spec.summary     = "Discourse plugin subscription client."
  spec.description = "Adds a backend subscription client to a Discourse plugin."
  spec.license     = "GPL-2.0-only"
  spec.required_ruby_version = ">= 2.6.0"

  spec.homepage = "https://github.com/paviliondev/discourse_subscription_client"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,extensions}/**/*", "LICENSE.txt", "COPYRIGHT.txt", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "active_model_serializers", "~> 0.8.3"
  spec.add_development_dependency "annotate"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "excon"
  spec.add_development_dependency "fabrication"
  spec.add_development_dependency "message_bus"
  spec.add_development_dependency "mini_scheduler"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "rails", ">= 7.0.4.1"
  spec.add_development_dependency "rspec-activemodel-mocks"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "sprockets-rails"
  spec.add_development_dependency "webmock"
end
