# frozen_string_literal: true

describe SubscriptionClientSupplier do
  let(:user) { create_discourse_user }
  let!(:supplier) do
    Fabricate(:subscription_client_supplier, api_key: Fabricate(:subscription_client_user_api_key),
                                             authorized_at: Time.now, user: user)
  end
  let!(:resource) { Fabricate(:subscription_client_resource, supplier: supplier) }
  let!(:subscription) { Fabricate(:subscription_client_subscription, resource: resource, subscribed: true) }

  it "destroys authorization" do
    stub_request(:post, "#{supplier.url}/user-api-key/revoke").to_return(status: 200, body: '{ "success": "OK" }')

    expect(supplier.destroy_authorization).to eq(true)
    expect(supplier.api_key).to eq(nil)
    expect(supplier.user_id).to eq(nil)
    expect(supplier.authorized_at).to eq(nil)
    expect(subscription.reload.subscribed).to eq(false)
  end
end
