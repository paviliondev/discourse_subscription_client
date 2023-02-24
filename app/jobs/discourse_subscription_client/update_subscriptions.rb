# frozen_string_literal: true

module DiscourseSubscriptionClient
  class UpdateSubscriptions < ::Jobs::Scheduled
    every 1.day

    def execute(_args = {})
      Subscriptions.update
    end
  end
end
