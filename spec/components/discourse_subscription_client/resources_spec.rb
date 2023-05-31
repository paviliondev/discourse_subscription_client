# frozen_string_literal: true

describe DiscourseSubscriptionClient::Resources, type: :multisite do
  let!(:supplier) { "Pavilion" }
  let!(:products) { { "subscription-plugin": [{ product_id: "prod_CBTNpi3fqWWkq0", product_slug: "business" }] } }

  before do
    DiscourseSubscriptionClient.stub(:root) { File.expand_path("../../fixtures", __dir__) }
  end

  it "finds all resources in all multisite instances" do
    test_multisite_connection("first") do
      stub_server_request("https://coop.pavilion.tech", supplier: supplier, products: products)
      DiscourseSubscriptionClient::Resources.find_all

      supplier = SubscriptionClientSupplier.find_by(name: "Pavilion")
      expect(supplier.present?).to eq(true)
      expect(supplier.products).to eq(products.as_json)
      expect(SubscriptionClientResource.exists?(name: "subscription-plugin")).to eq(true)
    end

    test_multisite_connection("second") do
      stub_server_request("https://coop.pavilion.tech", supplier: supplier, products: products)
      DiscourseSubscriptionClient::Resources.find_all

      supplier = SubscriptionClientSupplier.find_by(name: "Pavilion")
      expect(supplier.present?).to eq(true)
      expect(supplier.products).to eq(products.as_json)
      expect(SubscriptionClientResource.exists?(name: "subscription-plugin")).to eq(true)
    end
  end

  it "handles failed requests" do
    stub_server_request("https://coop.pavilion.tech", status: 404)
    DiscourseSubscriptionClient::Resources.find_all

    supplier = SubscriptionClientSupplier.find_by(name: "Pavilion")
    expect(supplier.present?).to eq(false)
    expect(SubscriptionClientResource.exists?(name: "subscription-plugin")).to eq(false)
  end
end
