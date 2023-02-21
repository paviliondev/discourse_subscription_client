# frozen_string_literal: true

class CreateSubscriptionClientSuppliers < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_client_suppliers, if_not_exists: true do |t|
      t.string :name
      t.string :url, null: false
      t.string :api_key
      t.references :user
      t.datetime :authorized_at

      t.timestamps
    end

    add_index :subscription_client_suppliers, [:url], unique: true, if_not_exists: true
  end
end
