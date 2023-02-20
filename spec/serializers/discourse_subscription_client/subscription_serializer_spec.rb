# frozen_string_literal: true

describe DiscourseSubscriptionClient::SubscriptionSerializer do
  let(:subscription_client_subscription) { Fabricate(:subscription_client_subscription) }

  it "should return subscription attributes" do
    serialized_json = described_class.new(subscription_client_subscription, root: false).to_json
    serialized_attrs = JSON.parse(serialized_json)
    %i[resource_name product_name price_name active].each do |key|
      expect(serialized_attrs[key.to_s]).to eq(subscription_client_subscription.send(key.to_s))
    end
  end
end
