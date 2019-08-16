# frozen_string_literal: true

RSpec.describe SidekiqPublisher::ReportUnpublishedCount do
  include_context "metrics_reporter context"

  describe ".call" do
    let(:job_count) { rand(1..100) }

    before do
      allow(SidekiqPublisher::Job).to receive_message_chain(:unpublished, :count). # rubocop:disable RSpec/MessageChain
        and_return(job_count)
    end

    it "records a gauge for the unpublished job count" do
      described_class.call

      expect(metrics_reporter).to have_received(:gauge).
        with("sidekiq_publisher.unpublished_count", job_count)
    end
  end
end
