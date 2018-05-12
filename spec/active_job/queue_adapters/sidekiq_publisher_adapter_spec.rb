# frozen_string_literal: true

RSpec.describe ActiveJob::QueueAdapters::SidekiqPublisherAdapter do
  let(:job_class) do
    Class.new(ActiveJob::Base) do
      self.queue_adapter = :sidekiq_publisher

      def perform(*args); end
    end
  end
  let(:args) { [1, 2, 3] }
  let(:active_job) { job_class.new(*args) }
  let(:job) { SidekiqPublisher::Job.last }

  before do
    stub_const("TestJob", job_class)
  end

  describe "#enqueue" do
    it "creates a SidekiqPublisher job" do
      active_job.enqueue

      expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
      expect(job.wrapped).to eq("TestJob")
      expect(job.args.first).to include("job_class" => "TestJob", "arguments" => args, "provider_job_id" => job.job_id)
    end
  end

  describe "#enqueue_at" do
    let(:scheduled_at) { 1.hour.from_now }

    it "creates a SidekiqPublisher job with a run_at value" do
      active_job.enqueue(wait_until: scheduled_at)

      expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
      expect(job.wrapped).to eq("TestJob")
      expect(job.args.first).to include("job_class" => "TestJob", "arguments" => args, "provider_job_id" => job.job_id)
      expect(job.run_at).to be_within(1).of(scheduled_at.to_f)
    end
  end

  describe "ActiveJob::Base.perform_later" do
    it "creates a SidekiqPublisher job" do
      job_class.perform_later(*args)

      expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
      expect(job.wrapped).to eq("TestJob")
      expect(job.args.dig(0, "arguments")).to eq(args)
    end
  end
end
