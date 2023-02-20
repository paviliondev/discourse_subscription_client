# frozen_string_literal: true

module DiscourseSubscriptionClient
  class Notices
    PLUGIN_STATUS_RESOURCE_ID = -1
    PLUGIN_STATUSES_TO_WARN = %w[incompatible tests_failing].freeze

    def initialize
      @suppliers = SubscriptionClientSupplier.authorized
    end

    def self.update(subscription: true, plugin: true)
      new.update(subscription: subscription, plugin: plugin)
    end

    def update(subscription: true, plugin: true)
      return if !SiteSetting.subscription_client_enabled || @suppliers.blank?

      if subscription
        @suppliers.each do |supplier|
          update_subscription_messages(supplier)
        end
      end

      update_plugin_statuses if plugin && SiteSetting.subscription_client_request_plugin_statuses

      SubscriptionClientNotice.publish_notice_count
    end

    def update_subscription_messages(supplier)
      url = "#{supplier.url}/subscription-server/messages"
      request = DiscourseSubscriptionClient::Request.new(:supplier, supplier.id)
      messages = request.perform(url)

      return unless messages.present?

      messages[:messages].each do |message|
        notice_type = SubscriptionClientNotice.types[message[:type].to_sym]

        if message[:resource] && (resource = SubscriptionClientResource.find_by(name: message[:resource],
                                                                                supplier_id: supplier.id))
          notice_subject_type = SubscriptionClientNotice.notice_subject_types[:resource]
          notice_subject_id = resource.id
        else
          notice_subject_type = SubscriptionClientNotice.notice_subject_types[:supplier]
          notice_subject_id = supplier.id
        end

        changed_at = message[:created_at]
        notice = SubscriptionClientNotice.find_by(
          notice_type: notice_type,
          notice_subject_type: notice_subject_type,
          notice_subject_id: notice_subject_id,
          changed_at: changed_at
        )

        if notice
          if message[:expired_at]
            notice.expired_at = message[:expired_at]
            notice.save
          end
        else
          SubscriptionClientNotice.create!(
            title: message[:title],
            message: message[:message],
            notice_type: notice_type,
            notice_subject_type: notice_subject_type,
            notice_subject_id: notice_subject_id,
            changed_at: changed_at,
            expired_at: message[:expired_at],
            retrieved_at: DateTime.now.iso8601(3)
          )
        end
      end
    end

    def update_plugin_statuses
      request = DiscourseSubscriptionClient::Request.new(:resource, PLUGIN_STATUS_RESOURCE_ID)
      response = request.perform(DiscourseSubscriptionClient.plugin_status_server_url)
      return false unless response && response[:statuses].present?

      statuses = response[:statuses]

      return unless statuses.present?

      warnings = statuses.select { |status| PLUGIN_STATUSES_TO_WARN.include?(status[:status]) }
      expiries = statuses - warnings

      create_plugin_warning_notices(warnings) if warnings.any?
      expire_plugin_warning_notices(expiries) if expiries.any?
    end

    def expire_plugin_warning_notices(expiries)
      plugin_names = expiries.map { |expiry| expiry[:name] }
      sql = <<~SQL
        UPDATE subscription_client_notices AS notices
        SET expired_at = now()
        FROM subscription_client_resources AS resources
        WHERE resources.name IN (:plugin_names)
        AND notices.notice_subject_id = resources.id
        AND notices.notice_subject_type = 'SubscriptionClientResource'
        AND notices.notice_type = :notice_type
      SQL

      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql(
          [
            sql, {
              notice_type: SubscriptionClientNotice.types[:warning],
              plugin_names: plugin_names
            }
          ]
        )
      )
    end

    def create_plugin_warning_notices(warnings)
      plugin_names = warnings.map { |warning| warning[:name] }
      resource_ids = SubscriptionClientResource.where(name: plugin_names)
                                               .each_with_object({}) do |resource, result|
        result[resource.name] =
          resource.id
      end

      warnings.each do |warning|
        notice_type = SubscriptionClientNotice.types[:warning]
        notice_subject_type = SubscriptionClientNotice.notice_subject_types[:resource]
        notice_subject_id = resource_ids[warning[:name]]
        changed_at = warning[:status_changed_at]

        notice = SubscriptionClientNotice.find_by(
          notice_type: notice_type,
          notice_subject_type: notice_subject_type,
          notice_subject_id: notice_subject_id,
          changed_at: changed_at
        )

        if notice
          notice.touch
        else
          SubscriptionClientNotice.create!(
            title: I18n.t("subscription_client.notices.compatibility_issue.title", resource: warning[:name]),
            message: I18n.t("subscription_client.notices.compatibility_issue.message", resource: warning[:name]),
            notice_type: notice_type,
            notice_subject_type: notice_subject_type,
            notice_subject_id: notice_subject_id,
            changed_at: changed_at,
            retrieved_at: DateTime.now.iso8601(3)
          )
        end
      end
    end
  end
end
