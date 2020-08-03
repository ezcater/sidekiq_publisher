# frozen_string_literal: true

RSpec.describe SidekiqPublisher::MetricsReporter do
  let(:event) { instance_double(ActiveSupport::Notifications::Event, payload: payload) }

  describe "PublisherSubscriber" do
    describe "#enqueue_batch" do
      let(:instance) { described_class::PublisherSubscriber.new }
      let(:payload) { { published_count: rand(1..100) } }

      context "when a metrics_reporter is configured" do
        include_context "metrics_reporter context"

        it "reports a count of the jobs published" do
          instance.enqueue_batch(event)

          expect(metrics_reporter).to have_received(:try).
            with(:count, "sidekiq_publisher.published", payload[:published_count])
        end
      end

      context "when there is no metrics_reporter configured" do
        it "does not raise an error" do
          expect do
            instance.enqueue_batch(event)
          end.not_to raise_error
        end
      end
    end
  end

  describe "JobSubscriber" do
    describe "#purge" do
      let(:instance) { described_class::JobSubscriber.new }
      let(:payload) { { purged_count: rand(1..100) } }

      context "when a metrics_reporter is configured" do
        include_context "metrics_reporter context"

        it "reports a count of the jobs purged" do
          instance.purge(event)

          expect(metrics_reporter).to have_received(:try).
            with(:count, "sidekiq_publisher.purged", payload[:purged_count])
        end
      end

      context "when there is no metrics_reporter configured" do
        it "does not raise an error" do
          expect do
            instance.purge(event)
          end.not_to raise_error
        end
      end
    end
  end

  describe "UnpublishedSubscriber" do
    describe "#unpublished" do
      let(:instance) { described_class::UnpublishedSubscriber.new }
      let(:payload) { { unpublished_count: rand(1..100) } }

      context "when a metrics_reporter is configured" do
        include_context "metrics_reporter context"

        it "reports a count of the jobs purged" do
          instance.unpublished(event)

          expect(metrics_reporter).to have_received(:try).
            with(:gauge, "sidekiq_publisher.unpublished_count", payload[:unpublished_count])
        end
      end

      context "when there is no metrics_reporter configured" do
        it "does not raise an error" do
          expect do
            instance.unpublished(event)
          end.not_to raise_error
        end
      end
    end
  end
end
