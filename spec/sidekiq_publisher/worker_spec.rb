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
