# frozen_string_literal: true

class SubscriptionClientResource < ActiveRecord::Base
  belongs_to :supplier, class_name: "SubscriptionClientSupplier"
  has_many :notices, class_name: "SubscriptionClientNotice", as: :notice_subject, dependent: :destroy
  has_many :subscriptions, foreign_key: "resource_id", class_name: "SubscriptionClientSubscription", dependent: :destroy
end

# == Schema Information
#
# Table name: subscription_client_resources
#
#  id          :bigint           not null, primary key
#  supplier_id :bigint
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_subscription_client_resources_on_supplier_id           (supplier_id)
#  index_subscription_client_resources_on_supplier_id_and_name  (supplier_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => subscription_client_suppliers.id)
#
