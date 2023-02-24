# frozen_string_literal: true

module DiscourseSubscriptionClient
  class FindResources < ::Jobs::Base
    def execute(_args = {})
      Resources.find_all unless Rails.env.test?
    end
  end
end
