# frozen_string_literal: true

Fabricator(:subscription_client_supplier) do
  name { "Pavilion" }
  url { sequence(:url) { |i| "https://supplier.com/#{i}/url" } }
end
