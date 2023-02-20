# frozen_string_literal: true

Fabricator(:subscription_client_subscription) do
  resource(fabricator: :subscription_client_resource)
  product_id { SecureRandom.hex(8) }
  product_name { sequence(:product_name) { |i| "Subscription #{i}" } }
  price_id { SecureRandom.hex(8) }
  price_name { sequence(:price_name) { |i| "Price #{i}" } }
  subscribed { true }
end
