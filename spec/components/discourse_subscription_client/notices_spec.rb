# frozen_string_literal: true

require "rails_helper"

describe DiscourseSubscriptionClient::Notices do
  let(:admin) { create_discourse_user(admin: true) }
  let!(:supplier) { Fabricate(:subscription_client_supplier, api_key: Fabricate(:subscription_client_user_api_key)) }
  let!(:resource) do
    Fabricate(:subscription_client_resource, name: "discourse-custom-wizard", supplier_id: supplier.id)
  end
  let(:subscription_message) do
    {
      title: "Title of message about subscription",
      message: "Message about subscription",
      type: "info",
      created_at: Time.now - 3.day,
      expired_at: nil
    }
  end
  let(:plugin_status) do
    {
      name: "discourse-custom-wizard",
      status: "incompatible",
      status_changed_at: Time.now - 3.day
    }
  end

  before do
    SiteSetting.subscription_client_request_plugin_statuses = true
  end

  context "with subscription" do
    before do
      freeze_time
      stub_subscription_messages_request(supplier, 200, [subscription_message])
    end

    it "converts subscription messages into notices" do
      described_class.update(plugin: false)

      notice = SubscriptionClientNotice.list.first
      expect(notice.notice_type).to eq(SubscriptionClientNotice.types[:info])
      expect(notice.message).to eq(subscription_message[:message])
      expect(notice.changed_at.to_datetime).to be_within(1.second).of(subscription_message[:created_at].to_datetime)
    end

    it "expires notice if subscription message is expired" do
      described_class.update(plugin: false)

      subscription_message[:expired_at] = Time.now
      stub_subscription_messages_request(supplier, 200, [subscription_message])
      described_class.update(plugin: false)

      notice = SubscriptionClientNotice.list(include_all: true).first
      expect(notice.expired?).to eq(true)
    end

    it "dismisses informational subscription notices" do
      described_class.update(plugin: false)

      notice = SubscriptionClientNotice.list(include_all: true).first
      expect(notice.dismissed?).to eq(false)

      notice.dismiss!
      expect(notice.dismissed?).to eq(true)
    end

    it "dismisses all informational subscription notices" do
      5.times do |index|
        subscription_message[:title] += " #{index}"
        subscription_message[:created_at] = subscription_message[:created_at] + (index + 1)
        stub_subscription_messages_request(supplier, 200, [subscription_message])
        described_class.update(plugin: false)
      end
      expect(SubscriptionClientNotice.list.count).to eq(5)
      SubscriptionClientNotice.dismiss_all
      expect(SubscriptionClientNotice.list.count).to eq(0)
    end

    it "publishes notices to admins" do
      messages = MessageBus.track_publish("/subscription_client_user") do
        described_class.update(plugin: false)
      end

      expect(messages.size).to eq(1)
      expect(messages.first.data[:visible_notice_count]).to eq(1)
      expect(messages.first.group_ids).to eq([Group::AUTO_GROUPS[:admins]])
    end

    context "with moderator subscription management" do
      before do
        SiteSetting.subscription_client_allow_moderator_subscription_management = true
      end

      it "publishes notices to staff" do
        messages = MessageBus.track_publish("/subscription_client_user") do
          described_class.update(plugin: false)
        end

        expect(messages.size).to eq(1)
        expect(messages.first.data[:visible_notice_count]).to eq(1)
        expect(messages.first.group_ids).to eq([Group::AUTO_GROUPS[:staff]])
      end
    end
  end

  context "with plugin status" do
    before do
      freeze_time
      stub_plugin_status_request(200, { statuses: [plugin_status], total: 1 })
      described_class.update(subscription: false)
    end

    it "converts warning into notice" do
      notice = SubscriptionClientNotice.list.first
      expect(notice.notice_type).to eq(SubscriptionClientNotice.types[:warning])
      expect(notice.message).to eq(I18n.t("subscription_client.notices.compatibility_issue.message",
                                          resource: plugin_status[:name]))
      expect(notice.changed_at.to_datetime).to be_within(1.second).of(plugin_status[:status_changed_at].to_datetime)
    end

    it "expires warning notices if status is recommended or compatible" do
      plugin_status[:status] = "compatible"
      plugin_status[:status_changed_at] = Time.now
      stub_plugin_status_request(200, { statuses: [plugin_status], total: 1 })
      described_class.update(subscription: false)

      notice = SubscriptionClientNotice.list(notice_type: SubscriptionClientNotice.types[:warning],
                                             include_all: true).first
      expect(notice.expired?).to eq(true)
    end

    it "hides plugin status warnings" do
      notice = SubscriptionClientNotice.list.first
      expect(notice.hidden?).to eq(false)

      notice.hide!
      expect(notice.hidden?).to eq(true)
    end
  end

  it "lists notices not expired more than a day ago" do
    subscription_message[:expired_at] = Time.now - 8.hours
    stub_subscription_messages_request(supplier, 200, [subscription_message])
    stub_plugin_status_request(200, { statuses: [plugin_status], total: 1 })

    described_class.update
    expect(SubscriptionClientNotice.list(include_all: true).length).to eq(2)
  end
end
