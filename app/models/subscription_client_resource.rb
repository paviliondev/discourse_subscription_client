# frozen_string_literal: true

require "aws-sdk-s3"

class SubscriptionClientResource < ActiveRecord::Base
  belongs_to :supplier, class_name: "SubscriptionClientSupplier"
  has_many :notices, class_name: "SubscriptionClientNotice", as: :notice_subject, dependent: :destroy
  has_many :subscriptions, foreign_key: "resource_id", class_name: "SubscriptionClientSubscription", dependent: :destroy

  def get_source_url(bucket)
    return nil unless access_key_id && secret_access_key && s3_client
    return nil unless can_access_bucket?(bucket)

    "s3://#{access_key_id}:#{secret_access_key}@#{bucket}"
  end

  def can_access_bucket?(bucket)
    s3_client.head_bucket(bucket: bucket)
    true
  rescue Aws::S3::Errors::BadRequest,
         Aws::S3::Errors::Forbidden,
         Aws::S3::Errors::NotFound
    false
  end

  def s3_client
    @s3_client ||= begin
      return nil unless access_key_id && secret_access_key

      Aws::S3::Client.new(
        region: "us-east-1",
        access_key_id: access_key_id,
        secret_access_key: secret_access_key
      )
    end
  end
end

# == Schema Information
#
# Table name: subscription_client_resources
#
#  id                :bigint           not null, primary key
#  supplier_id       :bigint
#  name              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  access_key_id     :string
#  secret_access_key :string
#
