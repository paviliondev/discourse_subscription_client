# frozen_string_literal: true

describe DiscourseSubscriptionClient do
  let(:user) { create_discourse_user }
  let!(:supplier) { Fabricate(:subscription_client_supplier) }
  let!(:resource1) { Fabricate(:subscription_client_resource, supplier: supplier) }
  let!(:resource2) { Fabricate(:subscription_client_resource, supplier: supplier) }

  context "#find_subscriptions" do
    context "without a resource name" do
      it "returns nil" do
        result = DiscourseSubscriptionClient.find_subscriptions
        expect(result).to eq(nil)
      end
    end

    context "without subscriptions" do
      it "returns any empty result" do
        result = DiscourseSubscriptionClient.find_subscriptions(resource1.name)
        expect(result.any?).to eq(false)
      end
    end

    context "with subscriptions" do
      let!(:subscription1) { Fabricate(:subscription_client_subscription, resource: resource1) }
      let!(:subscription2) { Fabricate(:subscription_client_subscription, resource: resource1) }
      let!(:subscription3) { Fabricate(:subscription_client_subscription, resource: resource2) }

      it "returns the supplier, resource and subscriptions" do
        result = DiscourseSubscriptionClient.find_subscriptions(resource1.name)
        expect(result.any?).to eq(true)
        expect(result.supplier).to eq(supplier)
        expect(result.resource).to eq(resource1)
        expect(result.subscriptions).to contain_exactly(subscription1, subscription2)
      end
    end
  end
end
