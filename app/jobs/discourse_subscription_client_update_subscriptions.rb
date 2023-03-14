# frozen_string_literal: true

module Jobs
  class DiscourseSubscriptionClientUpdateSubscriptions < ::Jobs::Scheduled
    every 1.day

    MAX_RETRY_COUNT = 4
    RETRY_BACKOFF = 5

    def execute(args = {})
      retry_count = args[:retry_count] || 0

      result = DiscourseSubscriptionClient::Subscriptions.update

      return unless result.errors["supplier_connection"].present?

      retry_count += 1
      return if retry_count > MAX_RETRY_COUNT

      delay = RETRY_BACKOFF * (retry_count - 1)
      ::Jobs.enqueue_in(delay.minutes, :disocurse_subscription_client_update_subscriptions, { retry_count: retry_count })
    end
  end
end
