# frozen_string_literal: true

describe DiscourseSubscriptionClient::SubscriptionsController do
  let(:user) { create_discourse_user(admin: true) }
  let(:authorized_at) { Time.now }
  let!(:supplier) do
    Fabricate(:subscription_client_supplier, api_key: Fabricate(:subscription_client_user_api_key),
                                             authorized_at: authorized_at, user: user)
  end
  let!(:resource) { Fabricate(:subscription_client_resource, supplier: supplier) }
  let!(:subscription) { Fabricate(:subscription_client_subscription, resource: resource) }

  before do
    sign_in(user)
  end

  it "returns subscriptions" do
    get "/admin/plugins/subscription-client/subscriptions.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body.size).to eq(1)
  end

  it "updates subscriptions" do
    stub_subscription_request(200, resource, { subscriptions: [] })
    post "/admin/plugins/subscription-client/subscriptions.json"
    expect(response.status).to eq(200)
    expect(subscription.reload.subscribed).to eq(false)
  end
end
