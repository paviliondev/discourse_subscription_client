# frozen_string_literal: true

require "rails_helper"

describe DiscourseSubscriptionClient::Authorization do
  let(:user) { create_discourse_user(admin: true) }
  let!(:supplier) { Fabricate(:subscription_client_supplier) }

  def raw_auth_payload(request_id)
    keys = described_class.get_keys(request_id)
    {
      key: "12345",
      nonce: keys.nonce,
      push: false,
      api: 4
    }
  end

  def generate_auth_payload(user_id, request_id)
    described_class.generate_keys(user_id, request_id)
    keys = described_class.get_keys(request_id)
    public_key = OpenSSL::PKey::RSA.new(keys.pem)
    Base64.encode64(public_key.public_encrypt(raw_auth_payload(request_id).to_json))
  end

  it "generates a valid authentication request url" do
    request_id = SecureRandom.hex(32)
    uri = URI(described_class.url(user, supplier, request_id))
    expect(uri.host).to eq(URI(supplier.url).host)

    parsed_query = Rack::Utils.parse_query uri.query
    expect(parsed_query["public_key"].present?).to eq(true)
    expect(parsed_query["nonce"].present?).to eq(true)
    expect(parsed_query["client_id"].present?).to eq(true)
    expect(parsed_query["auth_redirect"].present?).to eq(true)
    expect(parsed_query["application_name"]).to eq(SiteSetting.title)
    expect(parsed_query["scopes"]).to eq(described_class::SCOPE)
  end

  it "handles authorization response if request is valid" do
    request_id = SecureRandom.hex(32)
    payload = generate_auth_payload(user.id, request_id)
    result = raw_auth_payload(request_id)
    expect(described_class.process_response(request_id, payload)).to eq(result.merge(user_id: user.id))
  end

  it "discards authentication response if request is invalid" do
    payload = generate_auth_payload(user.id, SecureRandom.hex(32))
    expect(described_class.process_response(SecureRandom.hex(32), payload)).to eq(false)
  end
end
