# frozen_string_literal: true

RSpec.describe SidekiqPublisher::Instrumenter do
  let(:instrumenter) { described_class.new }
  let(:payload) { Hash.new[a: 1] }

  context "when ActiveSupport::Notifications is defined" do
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

  context "when ActiveSupport::Notifications is not defined" do
    before do
      hide_const("ActiveSupport::Notifications")
    end

    it "is a no-op" do
      instrumenter.instrument("foo", payload)
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
