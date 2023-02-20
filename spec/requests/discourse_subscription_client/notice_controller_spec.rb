# frozen_string_literal: true

describe DiscourseSubscriptionClient::NoticesController do
  let(:admin_user) { create_discourse_user(admin: true) }
  let!(:supplier) { Fabricate(:subscription_client_supplier) }
  let!(:resource) { Fabricate(:subscription_client_resource, supplier: supplier) }
  let(:subscription_notice_params) do
    {
      notice_type: SubscriptionClientNotice.types[:info],
      notice_subject_type: SubscriptionClientNotice.notice_subject_types[:supplier],
      notice_subject_id: supplier.id
    }
  end
  let!(:subscription_message_notice) { Fabricate(:subscription_client_notice, subscription_notice_params) }
  let(:plugin_status_notice) do
    Fabricate(:subscription_client_notice,
              notice_type: SubscriptionClientNotice.types[:warning],
              notice_subject_type: SubscriptionClientNotice.notice_subject_types[:resource],
              notice_subject_id: resource.id)
  end

  before do
    sign_in(admin_user)
  end

  it "lists notices" do
    get "/admin/plugins/subscription-client/notices.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["notices"][0]["id"]).to eq(subscription_message_notice.id)
    expect(response.parsed_body["hidden_notice_count"]).to eq(0)
  end

  it "dismisses notices" do
    notice = subscription_message_notice

    put "/admin/plugins/subscription-client/notices/#{notice.id}/dismiss.json"
    expect(response.status).to eq(200)

    updated = SubscriptionClientNotice.find(notice.id)
    expect(updated.dismissed?).to eq(true)
  end

  it "hides notices" do
    notice = plugin_status_notice

    put "/admin/plugins/subscription-client/notices/#{notice.id}/hide.json"
    expect(response.status).to eq(200)

    updated = SubscriptionClientNotice.find(notice.id)
    expect(updated.hidden?).to eq(true)
  end
end
