# frozen_string_literal: true

module DiscourseSubscriptionClient
  class Resources
    attr_accessor :suppliers,
                  :resources

    def initialize
      @suppliers = []
      @resources = []
    end

    def self.find_all
      RailsMultisite::ConnectionManagement.each_connection do
        new.find_all
      end
    end

    def find_all
      return unless DiscourseSubscriptionClient.database_exists?

      setup_resources
      find_resources

      return unless @resources.any?

      ActiveRecord::Base.transaction do
        find_suppliers
        save_resources
      end
    end

    def setup_resources
      setup_plugins
    end

    def find_resources
      find_plugins
    end

    def find_suppliers
      supplier_urls = @resources.map { |resource| resource[:supplier_url] }.uniq.compact

      supplier_urls.each do |url|
        supplier = SubscriptionClientSupplier.find_or_create_by(url: url)
        request = DiscourseSubscriptionClient::Request.new(:supplier, supplier.id)
        data = request.perform("#{url}/subscription-server")

        if valid_supplier_data?(data)
          supplier.update(name: data[:supplier], products: data[:products])
          @suppliers << supplier
        end
      end
    end

    def save_resources
      @resources.each do |resource|
        supplier = @suppliers.select { |s| s.url === resource[:supplier_url] }.first

        next unless supplier.present?

        attrs = {
          supplier_id: supplier.id,
          name: resource[:name]
        }
        SubscriptionClientResource.create!(attrs) unless SubscriptionClientResource.exists?(attrs)
      end
    end

    def setup_plugins
      Plugin::Metadata::FIELDS << :subscription_url unless Plugin::Metadata::FIELDS.include?(:subscription_url)
      Plugin::Metadata.attr_accessor(:subscription_url)
    end

    def find_plugins
      Dir["#{DiscourseSubscriptionClient.root}/plugins/*/plugin.rb"].sort.each do |path|
        source = File.read(path)
        metadata = Plugin::Metadata.parse(source)

        next unless metadata.subscription_url.present?

        @resources << {
          name: metadata.name,
          supplier_url: ENV["TEST_SUBSCRIPTION_URL"] || metadata.subscription_url
        }
      end
    end

    def valid_supplier_data?(data)
      return false unless data.present? && data.is_a?(Hash)
      return false unless %i[supplier products].all? { |key| data.key?(key) }
      return false unless data[:supplier].is_a?(String)
      return false unless data[:products].is_a?(Hash)

      data[:products].all? do |_resource, products|
        products.is_a?(Array) &&
          products.all? do |product|
            %i[product_id product_slug].all? do |key|
              product.key?(key) && product[key].is_a?(String)
            end
          end
      end
    end
  end
end
