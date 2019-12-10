# frozen_string_literal: true

RSpec.describe SidekiqPublisher::Worker do
  let(:worker_class) do
    Class.new do
      include SidekiqPublisher::Worker
    end
  end
  let(:args) { [1, 2, 3] }
  let(:job) { SidekiqPublisher::Job.last }

  before do
    stub_const("TestWorker", worker_class)
  end

  describe ".sidekiq_client_push" do
    let(:redis) { Sidekiq.redis { |conn| conn } }

    before do
      Sidekiq.redis do |conn|
        conn.scan_each do |key|
          conn.del(key)
        end
      end
    end

    it "aliases Sidekiq::Worker's client_push method" do
      TestWorker.sidekiq_client_push(
        "class" => TestWorker,
        "args" => args
      )

      expect(redis.llen("queue:default")).to eq(1)
      expect(JSON.parse(redis.lindex("queue:default", 0))).
        to include("class" => "TestWorker", "args" => args)
    end
  end

  describe ".perform_async" do
    it "creates a SidekiqPublisher job" do
      TestWorker.perform_async(*args)

      expect(job.job_class).to eq("TestWorker")
      expect(job.args).to eq(args)
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

  context ".perform_in" do
    it "creates a SidekiqPublisher job" do
      TestWorker.perform_in(1.hour, *args)

      expect(job.job_class).to eq("TestWorker")
      expect(job.args).to eq(args)
      expect(job.run_at).to be_within(1).of(1.hour.from_now.to_f)
    end
  end

  context ".perform_at" do
    let(:run_at) { 2.hours.from_now }

    it "creates a SidekiqPublisher job" do
      TestWorker.perform_at(run_at, *args)

      expect(job.job_class).to eq("TestWorker")
      expect(job.args).to eq(args)
      expect(job.run_at).to be_within(1).of(run_at.to_f)
    end
  end
end
