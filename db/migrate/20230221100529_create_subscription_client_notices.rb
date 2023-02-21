# frozen_string_literal: true

class CreateSubscriptionClientNotices < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_client_notices do |t|
      t.string :title, null: false
      t.string :message
      t.integer :notice_type, null: false
      t.references :notice_subject, polymorphic: true
      t.datetime :changed_at
      t.datetime :retrieved_at
      t.datetime :dismissed_at
      t.datetime :expired_at
      t.datetime :hidden_at

      t.timestamps null: false
    end

    add_index :subscription_client_notices, %i[notice_type notice_subject_type notice_subject_id changed_at],
              unique: true, name: "sc_unique_notices", if_not_exists: true
  end
end
