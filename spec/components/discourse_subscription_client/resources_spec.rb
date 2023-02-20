# frozen_string_literal: true

describe DiscourseSubscriptionClient::Resources, type: :multisite, skip: true do
  before do
    DiscourseSubscriptionClient.stub(:root) { "#{Rails.root}/plugins/discourse-subscription-client/spec/fixtures" }
  end

  it "finds all resources in all multisite instances" do
    test_multisite_connection("default") do
      stub_server_request("https://coop.pavilion.tech", "Pavilion")
      DiscourseSubscriptionClient::Resources.find_all

      expect(SubscriptionClientSupplier.exists?(name: "Pavilion")).to eq(true)
      expect(SubscriptionClientResource.exists?(name: "subscription-plugin")).to eq(true)
    end

    test_multisite_connection("second") do
      stub_server_request("https://coop.pavilion.tech", "Pavilion")
      DiscourseSubscriptionClient::Resources.find_all

      expect(SubscriptionClientSupplier.exists?(name: "Pavilion")).to eq(true)
      expect(SubscriptionClientResource.exists?(name: "subscription-plugin")).to eq(true)
    end
  end
end
