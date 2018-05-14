# frozen_string_literal: true

RSpec.describe SidekiqPublisher::Client do
  let(:client) { described_class.new }
  let(:job_class) do
    Class.new do
      include SidekiqPublisher::Worker
    end
  end
  let(:redis) { Sidekiq.redis { |conn| conn } }

  before do
    stub_const("TestJobClass", job_class)

    Sidekiq.redis do |conn|
      conn.scan_each do |key|
        conn.del(key)
      end
    end
  end

  describe "#bulk_push" do
    context "a single item" do
      let(:args) { [1, 2, 3] }
      let(:push!) { client.bulk_push([{ "class" => TestJobClass, "args" => args }]) }

      it "enqueues a Sidekiq job" do
        push!

        expect(redis.llen("queue:default")).to eq(1)
        expect(JSON.parse(redis.lindex("queue:default", 0))).to include("class" => "TestJobClass", "args" => args)
      end

      it "returns the count of jobs enqueued" do
        expect(push!).to eq(1)
      end
    end

    context "multiple items" do
      let(:args_array) { [[1, 2, 3], [4, 5, 6]] }
      let(:push!) do
        client.bulk_push(args_array.map { |args| Hash["class" => TestJobClass, "args" => args] })
      end

      it "enqueues multiple Sidekiq jobs" do
        push!

        expect(redis.llen("queue:default")).to eq(2)

        # reverse is used because Sidekiq enqueues using LPUSH
        redis.lrange("queue:default", 0, 1).reverse.each_with_index do |job_json, i|
          expect(JSON.parse(job_json)).to include("class" => "TestJobClass", "args" => args_array[i])
        end
      end

      it "returns the count of jobs enqueued" do
        expect(push!).to eq(2)
      end
    end

    context "different jobs" do
      let(:jobs) do
        [
          { class: TestJobClass, args: [1, 2, 3] },
          { class: OtherTestJobClass, args: [{ "x" => 1 }] },
        ]
      end
      let(:push!) { client.bulk_push(jobs.map(&:stringify_keys)) }

      before do
        stub_const("OtherTestJobClass", Class.new { include SidekiqPublisher::Worker })
      end

      it "enqueues multiple Sidekiq jobs" do
        push!

        expect(redis.llen("queue:default")).to eq(2)
        redis.lrange("queue:default", 0, 1).reverse.each_with_index do |job_json, i|
          job = jobs[i]
          expect(JSON.parse(job_json)).to include("class" => job[:class].to_s, "args" => job[:args])
        end
      end

      it "returns the count of jobs enqueued" do
        expect(push!).to eq(2)
      end
    end
  end
end
