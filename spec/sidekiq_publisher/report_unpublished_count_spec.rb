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

    context "and a PG::ConnectionBad/PG::UnableToSend error is encountered" do
      before do
        allow(SidekiqPublisher::Job).to receive(:unpublished).and_raise(PG::ConnectionBad)
        allow(ActiveRecord::Base).to receive(:clear_active_connections!)
      end

      it "re-raises the DB error and attempts to reconnect the connections" do
        expect { described_class.call(instrumenter: instrumenter) }.to raise_error(PG::ConnectionBad)
        expect(ActiveRecord::Base).to have_received(:clear_active_connections!)
      end
    end
  end
end
