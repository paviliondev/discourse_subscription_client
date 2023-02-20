# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 20_230_220_130_259) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "subscription_client_notices", force: :cascade do |t|
    t.string "title", null: false
    t.string "message"
    t.integer "notice_type", null: false
    t.string "notice_subject_type"
    t.bigint "notice_subject_id"
    t.datetime "changed_at", precision: nil
    t.datetime "retrieved_at", precision: nil
    t.datetime "dismissed_at", precision: nil
    t.datetime "expired_at", precision: nil
    t.datetime "hidden_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[notice_subject_type notice_subject_id], name: "index_subscription_client_notices_on_notice_subject"
    t.index %w[notice_type notice_subject_type notice_subject_id changed_at], name: "sc_unique_notices",
                                                                              unique: true
  end

  create_table "subscription_client_requests", force: :cascade do |t|
    t.bigint "request_id"
    t.string "request_type"
    t.datetime "expired_at"
    t.string "message"
    t.integer "count"
    t.json "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscription_client_resources", force: :cascade do |t|
    t.bigint "supplier_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[supplier_id name], name: "index_subscription_client_resources_on_supplier_id_and_name", unique: true
    t.index ["supplier_id"], name: "index_subscription_client_resources_on_supplier_id"
  end

  create_table "subscription_client_subscriptions", force: :cascade do |t|
    t.bigint "resource_id"
    t.string "product_id", null: false
    t.string "product_name"
    t.string "price_id", null: false
    t.string "price_name"
    t.boolean "subscribed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[resource_id product_id price_id], name: "sc_unique_subscriptions", unique: true
    t.index ["resource_id"], name: "index_subscription_client_subscriptions_on_resource_id"
  end

  create_table "subscription_client_suppliers", force: :cascade do |t|
    t.string "name"
    t.string "url", null: false
    t.string "api_key"
    t.bigint "user_id"
    t.datetime "authorized_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_subscription_client_suppliers_on_url", unique: true
    t.index ["user_id"], name: "index_subscription_client_suppliers_on_user_id"
  end

  add_foreign_key "subscription_client_resources", "subscription_client_suppliers", column: "supplier_id"
  add_foreign_key "subscription_client_subscriptions", "subscription_client_resources", column: "resource_id"
end
