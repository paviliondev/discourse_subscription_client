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

      @result.errors.blank?
    end

    def update_supplier(supplier)
      resources = supplier.resources
      return unless resources.present?

      request = DiscourseSubscriptionClient::Request.new(:supplier, supplier.id)
      headers = { "User-Api-Key" => supplier.api_key }
      url = "#{supplier.url}/subscription-server/user-subscriptions"

      response = request.perform(url, headers: headers, body: { resources: resources.map(&:name) })
      return @result.connection_error(supplier) if response.nil?

      subscription_data = @result.retrieve_subscriptions(supplier, response)
      deactivate_missing_subscriptions(supplier, subscription_data)
      return @result.no_subscriptions(supplier) if subscription_data.blank?

      subscription_data.each do |data|
        if data.subscription.present?
          data.subscription.activate!
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
      end
    end

    def data_matches_subscription(data, subscription)
      data.required.all? { |k, v| subscription.send(k.to_s) == v }
    end

    def deactivate_missing_subscriptions(supplier, subscription_data)
      return unless supplier.subscriptions.present?

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
    end
  end
end
