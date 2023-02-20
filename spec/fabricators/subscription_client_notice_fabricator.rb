# frozen_string_literal: true

Fabricator(:subscription_client_notice) do
  title { sequence(:title) { |i| "Notice #{i}" } }
  message { sequence(:message) { |i| "Notice message #{i}" } }
  notice_type { SubscriptionClientNotice.types[:info] }
  notice_subject { Fabricate(:subscription_client_resource) }
  changed_at { Time.now }
end
