# frozen_string_literal: true

%w[
  ./discourse_subscription_client/version
  ./discourse_subscription_client/engine
  ./discourse_subscription_client/request
  ./discourse_subscription_client/authorization
  ./discourse_subscription_client/resources
  ./discourse_subscription_client/notices
  ./discourse_subscription_client/subscriptions
  ./discourse_subscription_client/subscriptions/result
  ../app/models/subscription_client_notice
  ../app/models/subscription_client_resource
  ../app/models/subscription_client_subscription
  ../app/models/subscription_client_supplier
  ../app/controllers/discourse_subscription_client/admin_controller
  ../app/controllers/discourse_subscription_client/subscriptions_controller
  ../app/controllers/discourse_subscription_client/suppliers_controller
  ../app/controllers/discourse_subscription_client/notices_controller
  ../app/serializers/discourse_subscription_client/supplier_serializer
  ../app/serializers/discourse_subscription_client/resource_serializer
  ../app/serializers/discourse_subscription_client/notice_serializer
  ../app/serializers/discourse_subscription_client/subscription_serializer
  ../app/jobs/regular/discourse_subscription_client/find_resources
  ../app/jobs/scheduled/discourse_subscription_client/update_subscriptions
  ../app/jobs/scheduled/discourse_subscription_client/update_notices
  ../extensions/discourse_subscription_client/current_user
  ../extensions/discourse_subscription_client/guardian
].each do |path|
  require_relative path
end
