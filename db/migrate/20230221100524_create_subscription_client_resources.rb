# frozen_string_literal: true

class CreateSubscriptionClientResources < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_client_resources, if_not_exists: true do |t|
      t.references :supplier, foreign_key: { to_table: :subscription_client_suppliers }
      t.string :name, null: false

      t.timestamps
    end

    add_index :subscription_client_resources, %i[supplier_id name], unique: true, if_not_exists: true
  end
end
