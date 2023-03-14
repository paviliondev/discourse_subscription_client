# frozen_string_literal: true

RSpec.describe Jobs::DiscourseSubscriptionClientUpdateSubscriptions do
  let(:result) { DiscourseSubscriptionClient::Subscriptions::UpdateResult.new }
  let(:subject_enqueued_in) { Jobs.enqueued_in[:disocurse_subscription_client_update_subscriptions] }

  context "when the update succeeds" do
    before do
      DiscourseSubscriptionClient::Subscriptions.stub(:update) { result }
    end

    it "does not enqueue retries" do
      described_class.new.execute
      expect(subject_enqueued_in.present?).to eq(false)
    end
  end

  context "when the update fails not due to supplier connection" do
    before do
      result.errors["invalid_response"] = "Failed to update to supplier"
      DiscourseSubscriptionClient::Subscriptions.stub(:update) { result }
    end

    it "does not enqueue retries" do
      described_class.new.execute
      expect(subject_enqueued_in.present?).to eq(false)
    end
  end

  context "when the update fails due to supplier connection" do
    before do
      result.errors["supplier_connection"] = "Failed to connnect to supplier"
      DiscourseSubscriptionClient::Subscriptions.stub(:update) { result }
    end

    it "enqueues retries" do
      retry_count = described_class::MAX_RETRY_COUNT - 1
      delay = described_class::RETRY_BACKOFF * retry_count

      described_class.new.execute(retry_count: retry_count)
      expect(subject_enqueued_in.present?).to eq(true)
      expect(subject_enqueued_in[:delay]).to eq(delay.minutes)
    end

    it "does not retry more than the maximum retry count" do
      described_class.new.execute(retry_count: described_class::MAX_RETRY_COUNT)
      expect(subject_enqueued_in.present?).to eq(false)
    end
  end
end
