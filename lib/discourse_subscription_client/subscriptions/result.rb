# frozen_string_literal: true

module DiscourseSubscriptionClient
  class Subscriptions
    class Result
      attr_accessor :supplier,
                    :resource,
                    :subscriptions,
                    :products

      def any?
        supplier.present? && resource.present? && subscriptions.present? && products.present?
      end
    end
  end
end
