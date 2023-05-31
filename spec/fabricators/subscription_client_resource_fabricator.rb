# frozen_string_literal: true

Fabricator(:subscription_client_resource) do
  supplier(fabricator: :subscription_client_supplier)
  name { sequence(:name) { |i| "resource-#{i}" } }

  after_create do |resource|
    resource.supplier.products ||= {}
    resource.supplier.products[resource.name] = [
      {
        product_id: "prod_CBTNpi3fqWWkq0",
        product_slug: "business"
      }
    ]
    resource.supplier.save!
  end
end
