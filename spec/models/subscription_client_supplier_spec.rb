# frozen_string_literal: true

describe SubscriptionClientSupplier do
  let(:user) { create_discourse_user }
  let!(:supplier) do
    Fabricate(:subscription_client_supplier, api_key: Fabricate(:subscription_client_user_api_key),
                                             authorized_at: Time.now, user: user)
  end
  let!(:resource) { Fabricate(:subscription_client_resource, supplier: supplier) }
  let!(:subscription) { Fabricate(:subscription_client_subscription, resource: resource, subscribed: true) }

  describe "#destroy_authorization" do
    context "when api key revocation succeeds" do
      it "destroys authorization" do
        stub_request(:post, "#{supplier.url}/user-api-key/revoke").to_return(status: 200, body: "{ \"success\": \"OK\" }")

        expect(supplier.destroy_authorization).to eq(1)
        expect(supplier.api_key).to eq(nil)
        expect(supplier.user_id).to eq(nil)
        expect(supplier.authorized_at).to eq(nil)
        expect(subscription.reload.subscribed).to eq(false)
      end
    end

    context "when api key revocation fails" do
      it "destroys authorization" do
        stub_request(:post, "#{supplier.url}/user-api-key/revoke").to_return(status: 400, body: "{ \"failed\": \"FAILED\" }")

        expect(supplier.destroy_authorization).to eq(1)
        expect(supplier.api_key).to eq(nil)
        expect(supplier.user_id).to eq(nil)
        expect(supplier.authorized_at).to eq(nil)
        expect(subscription.reload.subscribed).to eq(false)
      end
    end
  end

  describe "#product_slugs" do
    it "maps product slugs" do
      expect(supplier.product_slugs).to eq({})
      supplier.products = [{ product_id: "prod_CBTNpi3fqWWkq0", product_slug: "business" }].as_json
      supplier.save!
      expect(supplier.reload.product_slugs).to eq({ "prod_CBTNpi3fqWWkq0" => "business" })
    end
  end
end
