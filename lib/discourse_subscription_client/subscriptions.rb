# frozen_string_literal: true

module DiscourseSubscriptionClient
  class Subscriptions
    def initialize
      @suppliers = SubscriptionClientSupplier.authorized
    end

    def self.update
      new.update
    end

    def update
      return unless SiteSetting.subscription_client_enabled

      DiscourseSubscriptionClient::Resources.find_all

      @result = DiscourseSubscriptionClient::Subscriptions::UpdateResult.new

      if @suppliers.blank?
        @result.no_suppliers
      else
        @suppliers.each do |supplier|
          update_supplier(supplier)
        end
      end

      if @result.errors.any?
        @result.errors.each do |error|
          Rails.logger.error "DiscourseSubscriptionClient::Subscriptions.update: #{error}"
        end
      end

      if SiteSetting.subscription_client_verbose_logs && @result.infos.any?
        @result.infos.each do |info|
          Rails.logger.info "DiscourseSubscriptionClient::Subscriptions.update: #{info}"
        end
      end

      DiscourseEvent.trigger(:subscription_client_subscriptions_updated, @result)

      @result.errors.blank?
    end

    def update_supplier(supplier)
      resources = supplier.resources
      return unless resources.present?

      request = DiscourseSubscriptionClient::Request.new(:supplier, supplier.id)
      headers = { "User-Api-Key" => supplier.api_key }
      url = "#{supplier.url}/subscription-server/user-subscriptions"

      response = request.perform(url, headers: headers, body: { resources: resources.map(&:name) })
      return (supplier.deactivate_all_subscriptions! && @result.connection_error(supplier)) if response.nil?

      subscription_data = @result.retrieve_subscriptions(supplier, response)
      return supplier.deactivate_all_subscriptions! if subscription_data.blank?

      # deactivate any of the supplier's subscriptions not retrieved from supplier
      supplier.subscriptions.each do |subscription|
        has_match = false
        subscription_data.each do |data|
          if data_matches_subscription(data, subscription)
            data.subscription = subscription
            has_match = true
          end
        end
        subscription.deactivate! unless has_match
      end

      subscription_data.each do |data|
        if data.subscription.present?
          data.subscription.update(subscribed: true)
          data.subscription.touch

          @result.updated_subscription(supplier, subscription_ids: data.required)
        else
          subscription = SubscriptionClientSubscription.create!(data.create.merge(subscribed: true))

          if subscription
            @result.created_subscription(supplier, subscription_ids: data.required)
          else
            @result.failed_to_create_subscription(supplier, subscription_ids: data.required)
          end
        end

        data.resource.update(data.resource_data) if data.resource.present? && data.resource_data.present?
      end
    end

    def data_matches_subscription(data, subscription)
      data.required.all? { |k, v| subscription.send(k.to_s) == v }
    end
  end
end
