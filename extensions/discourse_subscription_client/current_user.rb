# frozen_string_literal: true

module DiscourseSubscriptionClient
  module CurrentUserSerializerExtension
    def subscription_notice_count
      SubscriptionClientNotice.list(visible: true).count
    end

    def include_subscription_notice_count?
      scope.can_manage_subscriptions?
    end

    def can_manage_subscriptions
      scope.can_manage_subscriptions?
    end
  end
end
