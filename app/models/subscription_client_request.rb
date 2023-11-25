# frozen_string_literal: true

# == Schema Information
#
# Table name: subscription_client_requests
#
#  id           :bigint           not null, primary key
#  request_id   :bigint
#  request_type :string
#  expired_at   :datetime
#  message      :string
#  count        :integer
#  response     :json
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class SubscriptionClientRequest < ActiveRecord::Base
end
