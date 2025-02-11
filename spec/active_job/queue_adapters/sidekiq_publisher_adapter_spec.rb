# frozen_string_literal: true

require "sidekiq/api"

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
    clear_redis
  end

  describe "#enqueue" do
    context "when in a transaction" do
      it "creates a SidekiqPublisher job record" do
        active_job.enqueue

        expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
        expect(job.wrapped).to eq("TestJob")
        expect(job.args.first).to include(
          "job_class" => "TestJob",
          "arguments" => args,
          "provider_job_id" => job.job_id
        )
      end

      it "does not enqueue directly to Redis" do
        active_job.enqueue

        queue = Sidekiq::Queue.new("default")
        expect(queue.size).to eq(0)
      end
    end

    context "when not in a transaction", run_outside_transaction: true do
      it "does not create a SidekiqPublisher job record" do
        active_job.enqueue

        expect(job).to be_nil
      end

      it "enqueues directly to Redis via Sidekiq" do
        active_job.enqueue

        queue = Sidekiq::Queue.new("default")
        expect(queue.size).to eq(1)

        sidekiq_job = queue.first
        expect(sidekiq_job.display_class).to eq("TestJob")
        expect(sidekiq_job.display_args).to eq(args)
      end
    end

    context "when not in a transaction and stage_to_database_outside_transaction true", run_outside_transaction: true do
      before do
        SidekiqPublisher.configure do |config|
          config.stage_to_database_outside_transaction = true
        end
      end

      it "creates a SidekiqPublisher job record" do
        active_job.enqueue

        expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
        expect(job.wrapped).to eq("TestJob")
        expect(job.args.first).to include(
          "job_class" => "TestJob",
          "arguments" => args,
          "provider_job_id" => job.job_id
        )
      end

      it "does not enqueue directly to Redis" do
        active_job.enqueue

        queue = Sidekiq::Queue.new("default")
        expect(queue.size).to eq(0)
      end
    end
  end

  describe "#enqueue_at" do
    let(:scheduled_at) { 1.hour.from_now }

    context "when in a transaction" do
      it "creates a SidekiqPublisher job record with a run_at value" do
        active_job.enqueue(wait_until: scheduled_at)

        expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
        expect(job.wrapped).to eq("TestJob")
        expect(job.args.first).to include(
          "job_class" => "TestJob",
          "arguments" => args,
          "provider_job_id" => job.job_id
        )
        expect(job.run_at).to be_within(1).of(scheduled_at.to_f)
      end

      it "does not enqueue directly to Redis" do
        active_job.enqueue(wait_until: scheduled_at)

        queue = Sidekiq::ScheduledSet.new
        expect(queue.size).to eq(0)
      end
    end

    context "when not in a transaction", run_outside_transaction: true do
      it "does not create a SidekiqPublisher job record" do
        active_job.enqueue(wait_until: scheduled_at)

        expect(job).to be_nil
      end

      it "enqueues directly to Redis via Sidekiq" do
        active_job.enqueue(wait_until: scheduled_at)

        queue = Sidekiq::ScheduledSet.new
        expect(queue.size).to eq(1)

        sidekiq_job = queue.first
        expect(sidekiq_job.display_class).to eq("TestJob")
        expect(sidekiq_job.display_args).to eq(args)
        expect(sidekiq_job.at).to be_within(1).of(scheduled_at)
      end
    end

    context "when not in a transaction and stage_to_database_outside_transaction true", run_outside_transaction: true do
      before do
        SidekiqPublisher.configure do |config|
          config.stage_to_database_outside_transaction = true
        end
      end

      it "creates a SidekiqPublisher job record with a run_at value" do
        active_job.enqueue(wait_until: scheduled_at)

        expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
        expect(job.wrapped).to eq("TestJob")
        expect(job.args.first).to include(
          "job_class" => "TestJob",
          "arguments" => args,
          "provider_job_id" => job.job_id
        )
        expect(job.run_at).to be_within(1).of(scheduled_at.to_f)
      end

      it "does not enqueue directly to Redis" do
        active_job.enqueue(wait_until: scheduled_at)

        queue = Sidekiq::ScheduledSet.new
        expect(queue.size).to eq(0)
      end
    end
  end

  describe "ActiveJob::Base.perform_later" do
    context "when in a transaction" do
      it "creates a SidekiqPublisher job record" do
        job_class.perform_later(*args)

        expect(job.job_class).to eq(described_class::JOB_WRAPPER_CLASS)
        expect(job.wrapped).to eq("TestJob")
        expect(job.args.dig(0, "arguments")).to eq(args)
      end

      it "does not enqueue directly to Redis" do
        job_class.perform_later(*args)

        queue = Sidekiq::Queue.new("default")
        expect(queue.size).to eq(0)
      end
    end

    context "when not in a transaction", run_outside_transaction: true do
      it "does not create a SidekiqPublisher job record" do
        job_class.perform_later(*args)

        expect(job).to be_nil
      end

      it "enqueues directly to Redis via Sidekiq" do
        job_class.perform_later(*args)

        queue = Sidekiq::Queue.new("default")
        expect(queue.size).to eq(1)

        sidekiq_job = queue.first
        expect(sidekiq_job.display_class).to eq("TestJob")
        expect(sidekiq_job.display_args).to eq(args)
      end
    end
  end
end
