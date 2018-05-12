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

  context "scopes" do
    let!(:unpublished_job) { create(:unpublished_job) }
    let!(:published_job) { create(:published_job) }

    describe ".published" do
      it "only returns published jobs" do
        expect(described_class.published).to contain_exactly(published_job)
      end
    end

    describe ".unpublished" do
      it "only returns unpublished jobs" do
        expect(described_class.unpublished).to contain_exactly(unpublished_job)
      end
    end

    describe ".purgeable" do
      let!(:purgeable_job) { create(:purgeable_job) }

      it "only returns purgeable jobs" do
        expect(described_class.purgeable).to contain_exactly(purgeable_job)
      end
    end
  end

  describe ".purge_expired_published!" do
    let!(:unpublished_job) { create(:unpublished_job) }
    let!(:published_job) { create(:published_job) }
    let!(:purgeable_job) { create(:purgeable_job) }
    let!(:old_unpublished_job) { create(:old_unpublished_job) }

    before { described_class.purge_expired_published! }

    it "deletes purgeable jobs" do
      expect(described_class.find_by(id: purgeable_job.id)).not_to be_present
    end

    it "does not delete unpublished jobs" do
      expect(described_class.find_by(id: unpublished_job.id)).to be_present
    end

    it "does not delete old, unpublished jobs" do
      expect(described_class.find_by(id: old_unpublished_job.id)).to be_present
    end

    it "does not delete recently published jobs" do
      expect(described_class.find_by(id: published_job.id)).to be_present
    end
  end

  describe ".published!" do
    let(:unpublished_ids) { create_list(:unpublished_job, 2).map(&:id) }

    it "marks the jobs with the specified ids as published" do
      described_class.published!(unpublished_ids)
      expect(described_class.where(id: unpublished_ids).unpublished).to be_empty
    end
  end

  describe ".unpublished_batches" do
    let!(:published_job) { create(:published_job) }
    let!(:unpublished_jobs) { create_list(:unpublished_job, 3) }
    let(:batch_size) { 2 }

    it "yields batches of unpublished jobs" do
      expected_args = unpublished_jobs.each_slice(batch_size).map do |slice|
        slice.map do |job|
          {
            id: job.id,
            job_id: job.job_id,
            job_class: job.job_class,
            args: job.args,
            run_at: nil,
            queue: nil,
            wrapped: nil,
          }
        end
      end
      expect do |blk|
        described_class.unpublished_batches(batch_size: batch_size, &blk)
      end.to yield_successive_args(*expected_args)
    end
  end
end
