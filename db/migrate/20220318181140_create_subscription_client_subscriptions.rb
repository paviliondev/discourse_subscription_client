# frozen_string_literal: true

class CreateSubscriptionClientSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :subscription_client_subscriptions do |t|
      t.references :resource, foreign_key: { to_table: :subscription_client_resources }
      t.string :product_id, null: false
      t.string :product_name
      t.string :price_id, null: false
      t.string :price_name
      t.boolean :subscribed, default: false, null: false

      t.timestamps null: false
    end

    add_index :subscription_client_subscriptions, %i[resource_id product_id price_id], unique: true,
                                                                                       name: "sc_unique_subscriptions"
  end
end
