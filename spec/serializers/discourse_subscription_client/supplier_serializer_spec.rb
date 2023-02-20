# frozen_string_literal: true

describe DiscourseSubscriptionClient::SupplierSerializer do
  let(:user) { create_discourse_user }
  let(:authorized_at) { Time.now }
  let(:supplier) do
    Fabricate(:subscription_client_supplier,
              api_key: Fabricate(:subscription_client_user_api_key),
              authorized_at: authorized_at,
              user: user)
  end

  it "should return supplier attributes" do
    serialized_supplier = described_class.new(supplier)
    expect(serialized_supplier.name).to eq(supplier.name)
    expect(serialized_supplier.user.username).to eq(user.username)
    expect(serialized_supplier.authorized_at).to eq_time(authorized_at)
  end
end
