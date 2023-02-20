# frozen_string_literal: true

module DiscourseSubscriptionClient
  class SubscriptionSerializer < ApplicationSerializer
    attributes :supplier_name,
               :resource_name,
               :product_name,
               :price_name,
               :active,
               :updated_at
  end
end
