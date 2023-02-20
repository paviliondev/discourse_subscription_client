# frozen_string_literal: true

module Jobs
  class SubscriptionClientUpdateNotices < ::Jobs::Scheduled
    every 5.minutes

    def execute(_args = {})
      DiscourseSubscriptionClient::Notices.update
    end
  end
end
