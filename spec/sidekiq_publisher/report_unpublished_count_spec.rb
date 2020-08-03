# frozen_string_literal: true

RSpec.describe SidekiqPublisher::ReportUnpublishedCount do
  let(:instrumenter) { instance_double(SidekiqPublisher::Instrumenter) }

  before do
    allow(instrumenter).to receive(:instrument)
  end

  describe ".call" do
    let(:job_count) { rand(1..100) }

    before do
      allow(SidekiqPublisher::Job).to receive_message_chain(:unpublished, :count). # rubocop:disable RSpec/MessageChain
        and_return(job_count)
    end

    context "with a metrics reporter configured", :integration do
      include_context "metrics_reporter context"

      it "records a gauge for the unpublished job count" do
        described_class.call

        expect(metrics_reporter).to have_received(:try).
          with(:gauge, "sidekiq_publisher.unpublished_count", job_count)
      end
    end

    it "instruments the number of unpublished jobs" do
      described_class.call(instrumenter: instrumenter)

      expect(instrumenter).to have_received(:instrument).
        with("unpublished.reporter", unpublished_count: job_count)
    end
  end
end
