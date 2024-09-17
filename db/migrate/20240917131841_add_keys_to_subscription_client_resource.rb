# frozen_string_literal: true

class AddKeysToSubscriptionClientResource < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_client_resources, :access_key_id, :string, if_not_exists: true
    add_column :subscription_client_resources, :secret_access_key, :string, if_not_exists: true
  end
end
