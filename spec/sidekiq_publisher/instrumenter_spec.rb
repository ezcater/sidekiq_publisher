# frozen_string_literal: true

RSpec.describe SidekiqPublisher::Instrumenter, run_outside_transaction: true do
  let(:instrumenter) { described_class.new }
  let(:payload) { Hash.new[a: 1] }

  describe "#instrument" do
    before do
      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
    end

    it "calls instrument on ActiveSupport::Notifications" do
      instrumenter.instrument("foo", payload)

      expect(ActiveSupport::Notifications).to have_received(:instrument).
        with("foo.sidekiq_publisher", payload)
    end

    context "with a block" do
      it "calls the block with the payload" do
        expect do |blk|
          instrumenter.instrument("foo", payload, &blk)
        end.to yield_with_args(payload)
      end
    end
  end
end
