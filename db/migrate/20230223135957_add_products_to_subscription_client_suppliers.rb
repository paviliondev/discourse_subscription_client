# frozen_string_literal: true

class AddProductsToSubscriptionClientSuppliers < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_client_suppliers, :products, :json, if_not_exists: true
  end
end
