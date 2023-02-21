# frozen_string_literal: true

class CreateSubscriptionClientRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_client_requests do |t|
      t.bigint :request_id
      t.string :request_type
      t.datetime :expired_at
      t.string :message
      t.integer :count
      t.json :response

      t.timestamps
    end
  end
end
