# frozen_string_literal: true

module DiscourseSubscriptionClientHelper
  def authenticate_subscription
    allow_any_instance_of(DiscourseSubscriptionClient::Authentication).to receive(:active).and_return(true)
  end

  def valid_subscription
    {
      product_id: "prod_CBTNpi3fqWWkq0",
      price_id: "price_id",
      price_name: "yearly"
    }
  end

  def invalid_subscription
    {
      product_id: "prod_CBTNpi3fqWWkq0",
      price_id: "price_id"
    }
  end

  def stub_subscription_request(status, resources, body)
    url = resources.first.supplier.url
    stub_request(:get, "#{url}/subscription-server/user-subscriptions?#{{ resources: resources.map(&:name) }.to_query}")
      .to_return(status: status, body: body.to_json)
  end

  def stub_server_request(server_url, supplier: nil, products: [], status: 200)
    body = {}
    body[:supplier] = supplier[:name] if supplier.present?
    body[:products] = products if products.present?

    stub_request(:get, "#{server_url}/subscription-server")
      .to_return(
        status: status,
        body: body.to_json
      )
  end

  def stub_subscription_messages_request(supplier, status, messages)
    stub_request(:get, "#{supplier.url}/subscription-server/messages").to_return(status: status,
                                                                                 body: { messages: messages }.to_json)
  end

  def stub_plugin_status_request(status, response)
    stub_request(:get, DiscourseSubscriptionClient.plugin_status_server_url).to_return(status: status,
                                                                                       body: response.to_json)
  end

  def raw_auth_payload(request_id)
    keys = DiscourseSubscriptionClient::Authorization.get_keys(request_id)
    {
      key: "12345",
      nonce: keys.nonce,
      push: false,
      api: 4
    }
  end

  def generate_auth_payload(user_id, request_id)
    DiscourseSubscriptionClient::Authorization.generate_keys(user_id, request_id)
    keys = DiscourseSubscriptionClient::Authorization.get_keys(request_id)
    public_key = OpenSSL::PKey::RSA.new(keys.pem)
    Base64.encode64(public_key.public_encrypt(raw_auth_payload(request_id).to_json))
  end
end
