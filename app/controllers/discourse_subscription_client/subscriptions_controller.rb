# frozen_string_literal: true

module DiscourseSubscriptionClient
  class SubscriptionsController < AdminController
    def index
      render_serialized(SubscriptionClientSubscription.all, SubscriptionSerializer, root: "subscriptions")
    end

    def update
      result = DiscourseSubscriptionClient::Subscriptions.update

      if result.errors.blank?
        render_serialized(SubscriptionClientSubscription.all, SubscriptionSerializer, root: "subscriptions")
      else
        render json: failed_json.merge(errors: result.errors)
      end
    end
  end
end
