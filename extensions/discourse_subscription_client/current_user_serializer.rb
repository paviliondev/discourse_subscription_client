# frozen_string_literal: true

module DiscourseSubscriptionClient
  module CurrentUserSerializerExtension
    def attributes
      super.tap do |attrs|
        attrs[:subscription_notice_count] = subscription_notice_count if include_subscription_notice_count?
        attrs[:can_manage_subscriptions] = can_manage_subscriptions
        attrs[:can_manage_suppliers] = can_manage_suppliers
      end
    end

    def subscription_notice_count
      SubscriptionClientNotice.list(visible: true).count
    end

    def include_subscription_notice_count?
      scope.can_manage_subscriptions?
    end

    def can_manage_subscriptions
      scope.can_manage_subscriptions?
    end

    def can_manage_suppliers
      scope.can_manage_suppliers?
    end
  end
end
