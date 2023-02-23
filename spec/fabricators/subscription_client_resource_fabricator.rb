# frozen_string_literal: true

Fabricator(:subscription_client_resource) do
  supplier(fabricator: :subscription_client_supplier)
  name { sequence(:name) { |i| "resource-#{i}" } }
end
