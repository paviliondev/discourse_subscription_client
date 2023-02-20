# frozen_string_literal: true

module DiscourseSubscriptionClient
  class NoticeSerializer < ApplicationSerializer
    attributes :id,
               :title,
               :message,
               :notice_type,
               :notice_subject_type,
               :notice_subject_id,
               :plugin_status_resource,
               :created_at,
               :expired_at,
               :updated_at,
               :dismissed_at,
               :retrieved_at,
               :hidden_at,
               :dismissable,
               :can_hide

    has_one :supplier, serializer: DiscourseSubscriptionClient::SupplierSerializer, embed: :objects
    has_one :resource, serializer: DiscourseSubscriptionClient::ResourceSerializer, embed: :objects

    def include_supplier?
      object.supplier.present?
    end

    def include_resource?
      object.resource.present?
    end

    def plugin_status_resource
      object.plugin_status_resource?
    end

    def dismissable
      object.dismissable?
    end

    def can_hide
      object.can_hide?
    end

    def notice_type
      SubscriptionClientNotice.types.key(object.notice_type)
    end

    def messsage
      PrettyText.cook(object.message)
    end
  end
end
