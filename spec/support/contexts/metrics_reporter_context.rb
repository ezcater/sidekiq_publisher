# frozen_string_literal: true

shared_context "metrics_reporter context" do
  let(:metrics_reporter) { double }

  before do
    SidekiqPublisher.configure { |config| config.metrics_reporter = metrics_reporter }
    allow(metrics_reporter).to receive(:try)
  end
end
