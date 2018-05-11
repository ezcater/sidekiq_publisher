RSpec.describe SidekiqPublisher::Job, type: :model do
  let(:job_class) { Class.new }
  let(:job_id) { described_class.generate_sidekiq_jid }

  before do
    stub_const("TestJob", job_class)
  end

  describe "#valid?" do
    it { is_expected.to validate_presence_of(:job_class) }
    it { is_expected.to validate_exclusion_of(:args).in_array([nil]) }
  end

  describe ".create!" do
    it "sets a job_id if unset" do
      job = described_class.create!(job_class: "Foo", args: [])
      expect(job.job_id).to match(/^[0-9a-f]{24}$/)
    end

    it "ensures that job_class is a string" do
      job = described_class.create!(job_class: TestJob, args: [])
      expect(job.job_class).to eq("TestJob")
    end
  end

  describe "#sidekiq_item" do
    let(:expected_item) do
      {
        "jid" => job_id,
        "class" => TestJob,
        "args" => [1, 2],
      }
    end
    let(:job) do
      described_class.new(job_id: job_id, job_class: "TestJob", args: [1, 2])
    end

    it "returns the item to publish to Sidekiq" do
      expect(job.sidekiq_item).to eq(expected_item)
    end

    context "all attributes" do
      let(:expected_item) do
        {
          "jid" => job_id,
          "class" => TestJob,
          "args" => [1, 2],
          "queue" => "default",
          "at" => job.run_at,
          "wrapped" => "Other",
        }
      end
      let(:job) do
        described_class.new(job_id: job_id,
                            job_class: "TestJob",
                            args: [1, 2],
                            queue: "default",
                            run_at: Time.now,
                            wrapped: "Other")
      end

      it "returns the item to publish to Sidekiq" do
        expect(job.sidekiq_item).to eq(expected_item)
      end
    end
  end

  describe "#publish" do
    let(:args) { Hash["x" => 1] }
    let(:job) { described_class.new(job_id: job_id, job_class: "TestJob", args: args) }

    before do
      allow(Sidekiq::Client).to receive(:push)
    end

    it "calls Sidekiq::Client.push with the item" do
      job.publish
      expect(Sidekiq::Client).to have_received(:push).
        with("jid" => job_id, "class" => TestJob, "args" => args)
    end
  end
end
