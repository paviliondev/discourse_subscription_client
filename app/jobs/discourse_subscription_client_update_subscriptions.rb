# frozen_string_literal: true

module Jobs
  class DiscourseSubscriptionClientUpdateSubscriptions < ::Jobs::Scheduled
    every 1.day

    def execute(_args = {})
      ::DiscourseSubscriptionClient::Subscriptions.update
    end
  end
end
