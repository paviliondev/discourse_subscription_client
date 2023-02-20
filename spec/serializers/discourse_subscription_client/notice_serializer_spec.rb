# frozen_string_literal: true

describe DiscourseSubscriptionClient::NoticeSerializer do
  let(:notice) { Fabricate(:subscription_client_notice) }

  it "should return notice attributes" do
    serialized_notice = described_class.new(notice)
    expect(serialized_notice.message).to eq(notice.message)
    expect(serialized_notice.notice_type).to eq(SubscriptionClientNotice.types.key(notice.notice_type))
    expect(serialized_notice.dismissable).to eq(true)
  end
end
