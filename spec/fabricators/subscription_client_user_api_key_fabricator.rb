# frozen_string_literal: true

class SubscriptionClientUserApiKey
  attr_accessor :application_name,
                :client_id,
                :scopes
end

Fabricator(:subscription_client_user_api_key) do
  client_id { SecureRandom.hex }
  application_name "some app"
  scopes { OpenStruct.new(name: "discourse-subscription-server:user_subscription") }
end
