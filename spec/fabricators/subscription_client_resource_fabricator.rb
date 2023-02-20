# frozen_string_literal: true

Fabricator(:subscription_client_resource) do
  supplier(fabricator: :subscription_client_supplier)
  name { "custom-wizard-plugin" }
end
