# frozen_string_literal: true

RSpec.describe SidekiqPublisher do
  describe ".batch_size" do
    context "when unset" do
      it "returns the default" do
        expect(described_class.batch_size).to eq(described_class::DEFAULT_BATCH_SIZE)
      end
    end

    context "when set" do
      let(:batch_size) { rand(1..99) }

      before do
        described_class.batch_size = batch_size
      end

      it "returns the configured value" do
        expect(described_class.batch_size).to eq(batch_size)
      end
    end
  end

  describe ".job_retention_period" do
    context "when unset" do
      it "returns the default" do
        expect(described_class.job_retention_period).to eq(described_class::DEFAULT_JOB_RETENTION_PERIOD)
      end
    end

    context "when set" do
      let(:job_retention_period) { rand(1..24).hours }

      before do
        described_class.job_retention_period = job_retention_period
      end

      it "returns the configured value" do
        expect(described_class.job_retention_period).to eq(job_retention_period)
      end
    end
  end
end
