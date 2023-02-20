# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"

require "byebug"
require "active_model_serializers"
require "mini_scheduler"
require "message_bus"

module Discourse
  class Application < Rails::Application
    config.api_only = true
    config.load_defaults Rails::VERSION::STRING.to_f
    config.action_controller.include_all_helpers = false
    config.generators.system_tests = nil

    config.after_initialize do
      require "discourse_subscription_client"
    end
  end

  def self.current_hostname
    "localhost:4200"
  end

  def self.base_url
    "http://#{current_hostname}"
  end

  def self.base_url_no_prefix
    "http://#{current_hostname}"
  end
end

require_relative "../app/controllers/application_controller"
require_relative "../app/models/admin_dashboard_data"
require_relative "../app/models/user"
require_relative "../app/models/site_setting"
require_relative "../app/serializers/application_serializer"
require_relative "../app/serializers/basic_user_serializer"
require_relative "../app/serializers/current_user_serializer"
require_relative "../app/jobs/jobs"
require_relative "../lib/guardian"
require_relative "../lib/discourse_event"
require_relative "../lib/plugin_store"
require_relative "../lib/message_bus"

Bundler.require(*Rails.groups)
