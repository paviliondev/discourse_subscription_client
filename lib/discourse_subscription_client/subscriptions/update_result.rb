# frozen_string_literal: true

module ::DiscourseSubscriptionClient
  class Subscriptions
    class UpdateResult
      REQUIRED_KEYS ||= %i[
        resource_id
        product_id
        price_id
      ].freeze
      OPTIONAL_KEYS ||= %i[
        product_name
        price_name
      ].freeze
      KEYS = REQUIRED_KEYS + OPTIONAL_KEYS

      attr_reader :errors,
                  :infos

      def initialize
        @errors = {}
        @infos = {}
      end

      def not_authorized(supplier)
        error("not_authorized", supplier)
      end

      def retrieve_subscriptions(supplier, raw_data)
        unless raw_data[:subscriptions].is_a?(Array)
          error("invalid_response", supplier)
          return []
        end

        return [] unless raw_data[:subscriptions].any?

        subscriptions_data = raw_data[:subscriptions].compact

        # subscriptions must be properly formed

        subscriptions_data =
          subscriptions_data
          .map(&:symbolize_keys)
          .each { |data| data[:resource_id] = data[:resource] }
          .select { |data| REQUIRED_KEYS.all? { |key| data.key?(key) } }

        # we only care about subscriptions for resources on this instance

        resources = SubscriptionClientResource.where(
          supplier_id: supplier.id,
          name: subscriptions_data.map { |data| data[:resource] }
        )

        subscriptions_data.each_with_object([]) do |data, result|
          resource = resources.select { |r| r.name === data[:resource] }.first

          if resource.present?
            data[:resource_id] = resource.id
            result << OpenStruct.new(
              required: data.slice(*REQUIRED_KEYS),
              create: data.slice(*KEYS),
              subscription: nil
            )
          else
            info("no_resource", supplier, resource: data[:resource])
          end
        end
      end

      def connection_error(supplier)
        error("supplier_connection", supplier)
      end

      def no_suppliers
        info("no_suppliers")
      end

      def no_subscriptions(supplier)
        info("no_subscriptions", supplier)
      end

      def updated_subscription(supplier, subscription_ids: nil)
        info("updated_subscription", supplier, subscription_ids: subscription_ids)
      end

      def created_subscription(supplier, subscription_ids: nil)
        info("created_subscription", supplier, subscription_ids: subscription_ids)
      end

      def failed_to_create_subscription(supplier, subscription_ids: nil)
        info("failed_to_create_subscription", supplier, subscription_ids: subscription_ids)
      end

      def info(key, supplier = nil, subscription_ids: nil, resource: nil)
        attrs = {}

        if supplier
          attrs = {
            supplier: supplier.name,
            supplier_url: supplier.url,
            deep_interpolation: true,
            price: "",
            resource_name: ""
          }
        end

        attrs.merge!(subscription_ids) if subscription_ids.present?
        attrs[:resource] if resource.present?

        @infos[key] = I18n.t("subscription_client.subscriptions.info.#{key}", **attrs)
      end

      def error(key, supplier)
        @errors[key] = I18n.t("subscription_client.subscriptions.error.#{key}", supplier: supplier.name,
                                                                                supplier_url: supplier.url)
      end
    end
  end
end
