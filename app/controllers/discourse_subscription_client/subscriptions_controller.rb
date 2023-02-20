# frozen_string_literal: true

module DiscourseSubscriptionClient
  class SubscriptionsController < AdminController
    def index
      render_serialized(SubscriptionClientSubscription.all, SubscriptionSerializer, root: "subscriptions")
    end

    def update
      if DiscourseSubscriptionClient::Subscriptions.update
        render_serialized(SubscriptionClientSubscription.all, SubscriptionSerializer, root: "subscriptions")
      else
        render json: failed_json
      end
    end
  end
end
