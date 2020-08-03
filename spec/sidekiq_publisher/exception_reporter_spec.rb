# frozen_string_literal: true

RSpec.describe SidekiqPublisher::ExceptionReporter do
  describe "PublisherErrorSubscriber" do
    let(:instance) { described_class::PublisherErrorSubscriber.new }
    let(:event) { instance_double(ActiveSupport::Notifications::Event, payload: payload) }
    let(:error) { RuntimeError.new("boom") }
    let(:payload) do
      { exception_object: error, exception: [error.class.name, error.message] }
    end

    describe "#error" do
      context "when an exception reporter is configured" do
        let(:exception_reporter) { instance_double(Proc) }

        before do
          allow(exception_reporter).to receive(:call)
          SidekiqPublisher.exception_reporter = exception_reporter
        end

        it "reports the error to the exception reporter" do
          instance.error(event)

          expect(SidekiqPublisher.exception_reporter).to have_received(:call).with(error)
        end
      end

      context "without an exception reporter" do
        it "does not raise an error" do
          expect do
            instance.error(event)
          end.not_to raise_error
        end
      end
    end
  end
end
