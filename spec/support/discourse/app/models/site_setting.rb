# frozen_string_literal: true

class SiteSetting < ActiveRecord::Base
  cattr_accessor(:subscription_client_enabled) { true }
  cattr_accessor(:subscription_client_verbose_logs) { true }
  cattr_accessor(:subscription_client_warning_notices_on_dashboard) { true }
  cattr_accessor(:subscription_client_allow_moderator_subscription_management) { false }
  cattr_accessor(:subscription_client_allow_moderator_supplier_management) { false }
  cattr_accessor(:subscription_client_request_plugin_statuses) { false }
  cattr_accessor(:title) { "Test Discourse" }

  def self.load_settings(setting, plugin: ""); end
end
