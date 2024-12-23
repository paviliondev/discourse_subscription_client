# frozen_string_literal: true

module DiscourseSubscriptionClient
  PLUGIN_NAME ||= "discourse_subscription_client"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseSubscriptionClient

    def enabled_site_setting
      @enabled_site_setting = "subscription_client_enabled"
    end

    def configurable?
      true
    end

    config.before_initialize do
      config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
      Rails.autoloaders.main.ignore(config.root) if defined?(Rails) == "constant"
      Discourse.plugins_by_name[PLUGIN_NAME] = self
    end

    config.after_initialize do
      gem_root = File.expand_path("../..", __dir__)

      ActiveRecord::Tasks::DatabaseTasks.migrations_paths << "#{gem_root}/db/migrate" unless ENV["DISCOURSE_SUBSCRIPTION_CLIENT_SKIP_MIGRATIONS"]

      %w[
        ./request
        ./authorization
        ./resources
        ./s3_gem
        ./notices
        ./subscriptions
        ./subscriptions/result
        ./subscriptions/update_result
        ../../app/models/subscription_client_notice
        ../../app/models/subscription_client_resource
        ../../app/models/subscription_client_subscription
        ../../app/models/subscription_client_supplier
        ../../app/controllers/discourse_subscription_client/no_access_controller
        ../../app/controllers/discourse_subscription_client/admin_controller
        ../../app/controllers/discourse_subscription_client/subscriptions_controller
        ../../app/controllers/discourse_subscription_client/suppliers_controller
        ../../app/controllers/discourse_subscription_client/notices_controller
        ../../app/serializers/discourse_subscription_client/supplier_serializer
        ../../app/serializers/discourse_subscription_client/resource_serializer
        ../../app/serializers/discourse_subscription_client/notice_serializer
        ../../app/serializers/discourse_subscription_client/subscription_serializer
        ../../app/jobs/discourse_subscription_client/find_resources
        ../../app/jobs/discourse_subscription_client/update_subscriptions
        ../../app/jobs/discourse_subscription_client/update_notices
        ../../extensions/discourse_subscription_client/current_user_serializer
        ../../extensions/discourse_subscription_client/site_serializer
        ../../extensions/discourse_subscription_client/guardian
      ].each do |path|
        require_relative path
      end

      Jobs.enqueue(DiscourseSubscriptionClient::FindResources) if !Rails.env.test? && DiscourseSubscriptionClient.database_exists?

      Rails.application.routes.append do
        mount DiscourseSubscriptionClient::Engine, at: "/admin/plugins/subscription-client"
      end

      SiteSetting.load_settings("#{gem_root}/config/settings.yml", plugin: PLUGIN_NAME)

      Guardian.prepend DiscourseSubscriptionClient::GuardianExtension
      CurrentUserSerializer.prepend DiscourseSubscriptionClient::CurrentUserSerializerExtension
      SiteSerializer.prepend DiscourseSubscriptionClient::SiteSerializerExtension

      User.has_many(:subscription_client_suppliers)
      DiscourseEvent.trigger(:subscription_client_ready)
    end
  end

  class << self
    def root
      Rails.root
    end

    def plugin_status_server_url
      "https://coop.pavilion.tech"
    end

    def database_exists?
      ActiveRecord::Base.connection
    rescue ActiveRecord::NoDatabaseError
      false
    else
      true
    end

    def find_subscriptions(resource_name = nil)
      return nil unless resource_name

      subscriptions = SubscriptionClientSubscription.active
                                                    .includes(resource: [:supplier])
                                                    .references(resource: [:supplier])
                                                    .where("subscription_client_resources.name = ? ", resource_name)

      result = DiscourseSubscriptionClient::Subscriptions::Result.new
      return result unless subscriptions.exists?

      resource = subscriptions.first.resource
      supplier = resource.supplier
      products = supplier.product_slugs(resource_name)
      return result unless products.present?

      result.resource = resource
      result.supplier = supplier
      result.subscriptions = subscriptions.to_a
      result.products = products

      result
    end
  end
end
