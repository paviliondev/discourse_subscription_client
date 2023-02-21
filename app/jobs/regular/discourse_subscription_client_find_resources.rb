# frozen_string_literal: true

module Jobs
  class DiscourseSubscriptionClientFindResources < ::Jobs::Base
    def execute(_args = {})
      ::DiscourseSubscriptionClient::Resources.find_all unless Rails.env.test?
    end
  end
end
