# frozen_string_literal: true

module DiscourseSubscriptionClient
  class AdminController < ApplicationController
    requires_login
    before_action :ensure_can_manage_subscriptions

    def index
      respond_to do |format|
        format.html do
          render :index
        end
        format.json do
          render_json_dump(
            authorized_supplier_count: SubscriptionClientSupplier.authorized.count,
            resource_count: SubscriptionClientResource.count
          )
        end
      end
    end

    def ensure_can_manage_subscriptions
      Guardian.new(current_user).ensure_can_manage_subscriptions!
    end

    def failed_json
      { failed: "FAILED" }
    end

    def success_json
      { success: "OK" }
    end

    def render_serialized(objects, serializer, opts = {})
      render_json_dump(serialize_data(objects, serializer, opts))
    end

    def serialize_data(objects, serializer, opts = {})
      ActiveModel::ArraySerializer.new(objects.to_a, opts.merge(each_serializer: serializer)).as_json
    end

    def render_json_dump(json)
      render json: json, status: 200
    end
  end
end
