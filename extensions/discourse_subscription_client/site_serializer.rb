# frozen_string_literal: true

module DiscourseSubscriptionClient
  module SiteSerializerExtension
    def attributes
      super.tap do |attrs|
        attrs[:subscription_client_enabled] = subscription_client_enabled
      end
    end

    def subscription_client_enabled
      SiteSetting.subscription_client_enabled
    end
  end
end
