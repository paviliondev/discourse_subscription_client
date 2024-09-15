# frozen_string_literal: true

describe DiscourseSubscriptionClient::Subscriptions do
  let(:user) { create_discourse_user }
  let!(:supplier) { Fabricate(:subscription_client_supplier, api_key: Fabricate(:subscription_client_user_api_key)) }
  let!(:resource) { Fabricate(:subscription_client_resource, supplier: supplier) }
  let!(:old_subscription) { Fabricate(:subscription_client_subscription, resource: resource) }
  let!(:products) { { "subscription-plugin": [{ product_id: "prod_CBTNpi3fqWWkq0", product_slug: "business" }] } }
  let(:response_body) do
    {
      subscriptions: [
        {
          resource: resource.name,
          product_id: SecureRandom.hex(8),
          product_name: "Business Subscription",
          price_id: SecureRandom.hex(8),
          price_name: "Yearly"
        }
      ]
    }
  end

  before(:each) do
    stub_server_request(supplier.url, supplier: supplier, products: products, status: 200)
    allow_any_instance_of(DiscourseSubscriptionClient::Resources).to receive(:find_plugins).and_return([{ name: resource.name, supplier_url: supplier.url }])
  end

  it "updates subscriptions" do
    stub_subscription_request(200, resource, response_body)
    described_class.update

    subscription = SubscriptionClientSubscription.find_by(product_id: response_body[:subscriptions][0][:product_id])
    expect(subscription.present?).to eq(true)
    expect(subscription.subscribed).to eq(true)
  end

  it "deactivates subscriptions" do
    stub_subscription_request(200, resource, response_body)
    described_class.update
    expect(old_subscription.reload.subscribed).to eq(false)
  end

  it "reactivates subscriptions" do
    stub_subscription_request(200, resource, response_body)
    described_class.update

    subscription = SubscriptionClientSubscription.find_by(product_id: response_body[:subscriptions][0][:product_id])
    subscription.update(subscribed: false)

    described_class.update
    subscription.reload

    expect(subscription.subscribed).to eq(true)
  end

  it "deactivates subscriptions when no subscriptions are returned" do
    stub_subscription_request(
      404,
      resource,
      {
        error: "Failed to load discourse-custom-wizard subscriptions for #{user.username}: no subscriptions found for #{resource.name}"
      }
    )
    described_class.update

    expect(SubscriptionClientSubscription.exists?(product_id: response_body[:subscriptions][0][:product_id])).to eq(false)
  end

  it "deactivates subscriptions when there is a connection error" do
    stub_subscription_request(404, resource, {})
    described_class.update

    expect(SubscriptionClientSubscription.exists?(product_id: response_body[:subscriptions][0][:product_id])).to eq(false)
  end

  it "triggers an event" do
    stub_subscription_request(200, resource, response_body)
    DiscourseEvent
      .should_receive(:trigger)
      .with(
        :subscription_client_subscriptions_updated,
        instance_of(DiscourseSubscriptionClient::Subscriptions::UpdateResult)
      )
      .once
    described_class.update
  end
end
