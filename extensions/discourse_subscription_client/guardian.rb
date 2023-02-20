# frozen_string_literal: true

module DiscourseSubscriptionClient
  module GuardianExtension
    def can_manage_subscriptions?
      return false unless SiteSetting.subscription_client_enabled

      is_admin? || (
        is_staff? &&
        SiteSetting.subscription_client_allow_moderator_subscription_management
      )
    end

    def can_manage_suppliers?
      return false unless SiteSetting.subscription_client_enabled && can_manage_subscriptions?

      is_admin? || (
        is_staff? &&
        SiteSetting.subscription_client_allow_moderator_supplier_management
      )
    end
  end
end
