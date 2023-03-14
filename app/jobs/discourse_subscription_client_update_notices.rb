# frozen_string_literal: true

module Jobs
  class DiscourseSubscriptionClientUpdateNotices < ::Jobs::Scheduled
    every 5.minutes

    def execute(_args = {})
      Notices.update
    end
  end
end
