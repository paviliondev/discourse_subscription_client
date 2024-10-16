# frozen_string_literal: true

describe DiscourseSubscriptionClient::SuppliersController do
  let(:admin) { create_discourse_user(admin: true) }
  let(:moderator) { create_discourse_user(moderator: true) }
  let!(:supplier) { Fabricate(:subscription_client_supplier) }
  let!(:another_supplier) { Fabricate(:subscription_client_supplier) }
  let!(:products) do
    {
      "subscription-plugin" => [{ product_id: "prod_CBTNpi3fqWWkq0", product_slug: "business" }],
      "another-subscription-plugin" => [{ product_id: "prod_CBTNpi3fqWWkq1", product_slug: "standard" }]
    }
  end
  let!(:resource) do
    Fabricate(:subscription_client_resource,
              name: "subscription-plugin",
              supplier: supplier,
              products: [products["subscription-plugin"]])
  end
  let!(:another_resource) do
    Fabricate(:subscription_client_resource,
              name: "another-subscription-plugin",
              supplier: supplier,
              products: [products["another-subscription-plugin"]])
  end
  let(:subscription_response) do
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

  include_context "session double"

  before(:each) do
    allow_any_instance_of(DiscourseSubscriptionClient::Resources).to receive(:find_plugins).and_return(
      [
        { name: resource.name, supplier_url: supplier.url },
        { name: another_resource.name, supplier_url: supplier.url }
      ]
    )
    stub_server_request(supplier.url, supplier: supplier, products: products, status: 200)
  end

  describe "#index" do
    context "with admin" do
      before { sign_in(admin) }

      it "lists suppliers" do
        get "/admin/plugins/subscription-client/suppliers.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["suppliers"].size).to eq(2)
        expect(response.parsed_body["suppliers"].first["name"]).to eq(supplier.name)
      end

      it "filters suppliers by resource" do
        get "/admin/plugins/subscription-client/suppliers.json?resource=another-subscription-plugin"
        expect(response.status).to eq(200)
        expect(response.parsed_body["suppliers"].size).to eq(1)
        expect(response.parsed_body["suppliers"].first["name"]).to eq(supplier.name)
      end
    end
  end

  describe "#authorize" do
    context "with admin" do
      before { sign_in(admin) }

      it "authorizes" do
        get "/admin/plugins/subscription-client/suppliers/authorize", params: { supplier_id: supplier.id }
        expect(response.status).to eq(302)
        expect(@request.cookie_jar[:user_api_request_id].present?).to eq(true)
      end

      it "authorizes and stores requested landing page" do
        get "/admin/plugins/subscription-client/suppliers/authorize", params: {
          supplier_id: supplier.id,
          final_landing_path: "/admin/wizards/wizard"
        }
        expect(response.status).to eq(302)
        expect(session[:final_landing_path]).to eq("/admin/wizards/wizard")
      end
    end
  end

  describe "#authorize_callback" do
    context "with admin" do
      before { sign_in(admin) }

      it "handles authorization callbacks" do
        session_hash[:final_landing_path] = "/admin/plugins/subscription-client/subscriptions"
        request_id = cookies[:user_api_request_id] = DiscourseSubscriptionClient::Authorization.request_id(supplier.id)
        payload = generate_auth_payload(admin.id, request_id)
        stub_subscription_request(200, [resource, another_resource], subscription_response)

        get "/admin/plugins/subscription-client/suppliers/authorize/callback", params: { payload: payload }
        expect(response).to redirect_to("/admin/plugins/subscription-client/subscriptions")

        subscription = SubscriptionClientSubscription.find_by(resource_id: resource.id)
        expect(subscription.present?).to eq(true)
        expect(subscription.subscribed).to eq(true)
      end

      it "handles authorization callbacks and redirects to prior requested landing path" do
        session_hash[:final_landing_path] = "/admin/wizards/wizard"
        request_id = cookies[:user_api_request_id] = DiscourseSubscriptionClient::Authorization.request_id(supplier.id)
        payload = generate_auth_payload(admin.id, request_id)
        stub_subscription_request(200, [resource, another_resource], subscription_response)

        get "/admin/plugins/subscription-client/suppliers/authorize/callback", params: { payload: payload }
        expect(response).to redirect_to("/admin/wizards/wizard")
      end
    end
  end

  describe "#destroy" do
    context "with admin" do
      before { sign_in(admin) }

      it "destroys authorizations" do
        request_id = DiscourseSubscriptionClient::Authorization.request_id(supplier.id)
        payload = generate_auth_payload(admin.id, request_id)
        DiscourseSubscriptionClient::Authorization.process_response(request_id, payload)

        stub_request(:post, "#{supplier.url}/user-api-key/revoke").to_return(status: 200, body: '{ "success": "OK" }')

        delete "/admin/plugins/subscription-client/suppliers/authorize", params: { supplier_id: supplier.id }
        expect(response.status).to eq(200)
        expect(response.parsed_body["supplier_id"]).to eq(supplier.id)
        expect(supplier.authorized?).to eq(false)
      end
    end
  end

  context "with moderator allowed to manage subscriptions" do
    before do
      SiteSetting.subscription_client_allow_moderator_subscription_management = true
      sign_in(moderator)
    end

    before(:each) do
      allow_any_instance_of(DiscourseSubscriptionClient::Resources).to receive(:find_plugins)
        .and_return([{ name: resource.name, supplier_url: supplier.url }])
      stub_server_request(supplier.url, supplier: supplier, products: products, status: 200)
    end

    it "doesnt allow access" do
      get "/admin/plugins/subscription-client/suppliers.json"
      expect(response.status).to eq(403)
    end

    context "with subscription_client_allow_moderator_supplier_management enabled" do
      before do
        SiteSetting.subscription_client_allow_moderator_supplier_management = true
      end

      it "lists suppliers" do
        get "/admin/plugins/subscription-client/suppliers.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["suppliers"].size).to eq(2)
      end

      it "authorizes" do
        get "/admin/plugins/subscription-client/suppliers/authorize", params: { supplier_id: supplier.id }
        expect(response.status).to eq(302)
        expect(@request.cookie_jar[:user_api_request_id].present?).to eq(true)
      end

      it "handles authorization callbacks" do
        session_hash[:final_landing_path] = "/admin/plugins/subscription-client/subscriptions"
        request_id = cookies[:user_api_request_id] = DiscourseSubscriptionClient::Authorization.request_id(supplier.id)
        payload = generate_auth_payload(moderator.id, request_id)
        stub_subscription_request(200, [resource, another_resource], subscription_response)

        get "/admin/plugins/subscription-client/suppliers/authorize/callback", params: { payload: payload }
        expect(response).to redirect_to("/admin/plugins/subscription-client/subscriptions")

        subscription = SubscriptionClientSubscription.find_by(resource_id: resource.id)
        expect(subscription.present?).to eq(true)
        expect(subscription.subscribed).to eq(true)
      end

      it "destroys authorizations" do
        request_id = DiscourseSubscriptionClient::Authorization.request_id(supplier.id)
        payload = generate_auth_payload(moderator.id, request_id)
        DiscourseSubscriptionClient::Authorization.process_response(request_id, payload)

        stub_request(:post, "#{supplier.url}/user-api-key/revoke").to_return(status: 200,
                                                                             body: '{ "success": "OK" }')

        delete "/admin/plugins/subscription-client/suppliers/authorize", params: { supplier_id: supplier.id }
        expect(response.status).to eq(200)
        expect(supplier.authorized?).to eq(false)
      end
    end
  end
end
