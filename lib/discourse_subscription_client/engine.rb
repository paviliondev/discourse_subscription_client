# frozen_string_literal: true

module DiscourseSubscriptionClient
  PLUGIN_NAME ||= "discourse_subscription_client"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseSubscriptionClient

    config.before_initialize do
      config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
    end

    config.after_initialize do
      Jobs.enqueue(:subscription_client_find_resources) if DiscourseSubscriptionClient.database_exists? && !Rails.env.test?

      Rails.application.routes.append do
        mount DiscourseSubscriptionClient::Engine, at: "/admin/plugins/subscription-client"
      end

      SiteSetting.load_settings("config/settings", plugin: PLUGIN_NAME)

      Guardian.prepend DiscourseSubscriptionClient::GuardianExtension
      CurrentUserSerializer.prepend DiscourseSubscriptionClient::CurrentUserSerializerExtension

      User.has_many(:subscription_client_suppliers)

      AdminDashboardData.add_scheduled_problem_check(:subscription_client) do
        return unless SiteSetting.subscription_client_warning_notices_on_dashboard

        notices = SubscriptionClientNotice.list(
          notice_type: SubscriptionClientNotice.error_types,
          visible: true
        )
        notices.map do |notice|
          AdminDashboardData::Problem.new(
            "#{notice.title}: #{notice.message}",
            priority: "high",
            identifier: "subscription_client_notice_#{notice.id}"
          )
        end
      end

      DiscourseEvent.trigger(:subscription_client_ready)
    end
  end

  class << self
    def root
      Rails.root
    end

    def plugin_status_server_url
      "https://discourse.pluginmanager.org"
    end

    def database_exists?
      ActiveRecord::Base.connection
    rescue ActiveRecord::NoDatabaseError
      false
    else
      true
    end
  end
end
