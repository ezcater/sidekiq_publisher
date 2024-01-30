# frozen_string_literal: true

require "sidekiq/api"

RSpec.describe SidekiqPublisher::Worker do
  let(:worker_class) do
    Class.new do
      include SidekiqPublisher::Worker
    end
  end
  let(:args) { [1, 2, 3] }
  let(:job) { SidekiqPublisher::Job.last }
  let(:redis) { Sidekiq.redis { |conn| conn } }

  before do
    stub_const("TestWorker", worker_class)

    Sidekiq.redis do |conn|
      conn.scan_each do |key|
        conn.del(key)
      end
    end
  end

  describe ".sidekiq_client_push" do
    it "aliases Sidekiq::Worker's client_push method" do
      TestWorker.sidekiq_client_push(
        "class" => TestWorker,
        "args" => args
      )

      queue = Sidekiq::Queue.new("default")
      expect(queue.size).to eq(1)

      sidekiq_job = queue.first
      expect(sidekiq_job.display_class).to eq("TestWorker")
      expect(sidekiq_job.display_args).to eq(args)
    end
  end

  describe ".perform_async" do
    context "when in a transaction" do
      it "creates a SidekiqPublisher job record" do
        TestWorker.perform_async(*args)

        expect(job.job_class).to eq("TestWorker")
        expect(job.args).to eq(args)
      end
    end

    context "when not in a transaction", skip_db_clean: true do
      it "enqueues directly to Redis via Sidekiq" do
        TestWorker.perform_async(*args)

        expect(job).to be_nil

        queue = Sidekiq::Queue.new("default")
        expect(queue.size).to eq(1)

        sidekiq_job = queue.first
        expect(sidekiq_job.display_class).to eq("TestWorker")
        expect(sidekiq_job.display_args).to eq(args)
      end
    end

    context "when Sidekiq::Testing mode is inline" do
      let(:worker_class) do
        Class.new do
          include SidekiqPublisher::Worker

          class << self
            attr_accessor :count
          end

          self.count = 0

          def perform(incr)
            self.class.count += incr
          end
        end
      end

      around do |example|
        Sidekiq::Testing.inline! do
          example.run
        end
        Sidekiq::Testing.disable!
      end

      it "executes the job" do
        incr = rand(999)
        expect do
          TestWorker.perform_async(incr)
        end.to change(TestWorker, :count).by(incr)
      end
    end

    context "when Sidekiq::Testing mode is fake" do
      around do |example|
        Sidekiq::Testing.fake! do
          example.run
        end
        Sidekiq::Testing.disable!
      end

      it "adds the jobs to an array for the worker" do
        expect do
          TestWorker.perform_async(*args)
        end.to change(TestWorker.jobs, :size).by(1)
      end
    end
  end

  describe ".perform_in" do
    context "when in a transaction" do
      it "creates a SidekiqPublisher job record" do
        TestWorker.perform_in(1.hour, *args)

        expect(job.job_class).to eq("TestWorker")
        expect(job.args).to eq(args)
        expect(job.run_at).to be_within(1).of(1.hour.from_now.to_f)
      end
    end

    context "when not in a transaction", skip_db_clean: true do
      it "enqueues directly to Redis via Sidekiq" do
        TestWorker.perform_in(1.hour, *args)

        expect(job).to be_nil

        queue = Sidekiq::ScheduledSet.new
        expect(queue.size).to eq(1)

        sidekiq_job = queue.first
        expect(sidekiq_job.display_class).to eq("TestWorker")
        expect(sidekiq_job.display_args).to eq(args)
        expect(sidekiq_job.at).to be_within(1).of(1.hour.from_now)
      end
    end
  end

  describe ".perform_at" do
    let(:run_at) { 2.hours.from_now }

    context "when in a transaction" do
      it "creates a SidekiqPublisher job record" do
        TestWorker.perform_at(run_at, *args)

        expect(job.job_class).to eq("TestWorker")
        expect(job.args).to eq(args)
        expect(job.run_at).to be_within(1).of(run_at.to_f)
      end
    end

    context "when not in a transaction", skip_db_clean: true do
      it "enqueues directly to Redis via Sidekiq" do
        TestWorker.perform_at(run_at, *args)

        expect(job).to be_nil

        queue = Sidekiq::ScheduledSet.new
        expect(queue.size).to eq(1)

        sidekiq_job = queue.first
        expect(sidekiq_job.display_class).to eq("TestWorker")
        expect(sidekiq_job.display_args).to eq(args)
        expect(sidekiq_job.at).to be_within(1).of(run_at)
      end
    end
  end
end
