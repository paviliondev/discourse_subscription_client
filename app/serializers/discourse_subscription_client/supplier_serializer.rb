# frozen_string_literal: true

module DiscourseSubscriptionClient
  class SupplierSerializer < ApplicationSerializer
    attributes :id,
               :name,
               :authorized,
               :authorized_at

    has_one :user, serializer: BasicUserSerializer, embed: :objects

    def authorized
      object.api_key.present? && object.authorized_at.present?
    end
  end
end
