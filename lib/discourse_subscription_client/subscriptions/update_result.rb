# frozen_string_literal: true

module ::DiscourseSubscriptionClient
  class Subscriptions
    class UpdateResult
      REQUIRED_SUBSCRIPTION_KEYS ||= %i[
        resource_id
        product_id
        price_id
      ].freeze
      OPTIONAL_SUBSCRIPTION_KEYS ||= %i[
        product_name
        price_name
      ].freeze
      SUBSCRIPTION_KEYS = REQUIRED_SUBSCRIPTION_KEYS + OPTIONAL_SUBSCRIPTION_KEYS
      REQUIRED_RESOURCE_KEYS ||= %i[
        resource
        access_key_id
        secret_access_key
      ]

      attr_reader :errors,
                  :errored_suppliers,
                  :infos

      def initialize
        @errors = []
        @infos = []
      end

      def not_authorized(supplier)
        error("not_authorized", supplier)
      end

      def retrieve_subscriptions(supplier, raw_data)
        subscriptions_data = raw_data[:subscriptions].compact

        unless subscriptions_data.present? && subscriptions_data.is_a?(Array)
          error("invalid_response", supplier)
          return []
        end

        subscriptions_data = format_subscriptions_data(subscriptions_data)
        resources_data = format_resources_data(raw_data[:resources])

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
              required: data.slice(*REQUIRED_SUBSCRIPTION_KEYS),
              create: data.slice(*SUBSCRIPTION_KEYS),
              subscription: nil,
              resource: resource,
              resource_data: resources_data[resource.name]
            )
          else
            info("no_resource", supplier, resource: data[:resource])
          end
        end
      end

      def format_subscriptions_data(subscriptions_data)
        subscriptions_data
          .map(&:symbolize_keys)
          .each { |data| data[:resource_id] = data[:resource] }
          .select { |data| REQUIRED_SUBSCRIPTION_KEYS.all? { |key| data.key?(key) } }
      end

      def format_resources_data(resources_data)
        return {} unless resources_data

        resources_data
          .compact
          .map(&:symbolize_keys)
          .select { |data| REQUIRED_RESOURCE_KEYS.all? { |key| data.key?(key) } }
          .each_with_object({}) do |data, result|
            result[data[:resource]] = data.slice(:access_key_id, :secret_access_key)
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

        @infos << I18n.t("subscription_client.subscriptions.info.#{key}", **attrs)
      end

      def error(key, supplier)
        @errors << I18n.t("subscription_client.subscriptions.error.#{key}", supplier: supplier.name,
                                                                            supplier_url: supplier.url)
      end
    end
  end
end
