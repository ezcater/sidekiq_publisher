# frozen_string_literal: true

RSpec.describe SidekiqPublisher::Publisher do
  let(:client) { instance_double(SidekiqPublisher::Client) }
  let(:publisher) { described_class.new(instrumenter: instrumenter) }
  let(:test_job_class) { Class.new { include SidekiqPublisher::Worker } }
  let(:buffer) { Array.new }
  let(:job_model) { SidekiqPublisher::Job }
  let(:instrumenter) { instance_double(SidekiqPublisher::Instrumenter) }
  let(:payload) { Hash.new }

  before do
    stub_const("TestJobClass", test_job_class)
    stub_const("OtherTestJobClass", test_job_class.dup)
    allow(SidekiqPublisher::Client).to receive(:new).and_return(client)
    allow(client).to receive(:bulk_push) do |items|
      buffer << items
    end
    allow(instrumenter).to receive(:instrument).and_yield(Hash.new)
    allow(instrumenter).to receive(:instrument).with("error.publisher", instance_of(Hash)) # no yield
    allow(instrumenter).to receive(:instrument).with("publish_batch.publisher").and_yield
    allow(instrumenter).to receive(:instrument).with("enqueue_batch.publisher").and_yield(payload)
  end

  describe "#publish" do
    let!(:unpublished_jobs) do
      Array.new(2) { create(:unpublished_job) } +
        [create(:unpublished_job, job_class: "OtherTestJobClass")]
    end
    let(:batch_size) { 2 }
    let(:batch_slices) do
      unpublished_jobs.each_slice(batch_size).map do |slice|
        slice.map do |job|
          {
            "class" => job.job_class.constantize,
            "args" => job.args,
            "jid" => job.job_id,
            "created_at" => be_within(10**-3).of(job.created_at.to_f),
          }
        end
      end
    end

    before do
      SidekiqPublisher.batch_size = batch_size
    end

    it "publishes each job" do
      publisher.publish

      expect(client).to have_received(:bulk_push).with(batch_slices[0])
      expect(client).to have_received(:bulk_push).with(batch_slices[1])
    end

    it "caches job class lookup" do
      allow(ActiveSupport::Inflector).to receive(:constantize).and_call_original

      publisher.publish

      expect(ActiveSupport::Inflector).to have_received(:constantize).with("TestJobClass").once
      expect(ActiveSupport::Inflector).to have_received(:constantize).with("OtherTestJobClass").once
    end

    it "updates the status of each published job" do
      publisher.publish

      expect(job_model.published.pluck(:id)).to match_array(unpublished_jobs.map(&:id))
    end

    it "updates the status of a job once for normal execution" do
      allow(job_model).to receive(:published!).and_call_original
      publisher.publish

      # two batches
      expect(job_model).to have_received(:published!).twice
    end

    it "instruments publish activity" do
      publisher.publish

      expect(instrumenter).to have_received(:instrument).with("publish_batch.publisher").twice
      expect(instrumenter).to have_received(:instrument).with("enqueue_batch.publisher").twice
      expect(payload[:published_count]).to eq(1)
    end

    context "with a metrics reporter configured", :integration do
      include_context "metrics_reporter context"
      let(:instrumenter) { SidekiqPublisher::Instrumenter.new }

      before do
        # unstub
        allow(instrumenter).to receive(:instrument).and_call_original
      end

      it "records the count of jobs published in each batch" do
        publisher.publish

        expect(metrics_reporter).to have_received(:try).with(:count, "sidekiq_publisher.published", 2)
        expect(metrics_reporter).to have_received(:try).with(:count, "sidekiq_publisher.published", 1)
      end
    end

    context "job retention" do
      let!(:published_job) { create(:published_job) }
      let!(:purgeable_job) { create(:purgeable_job) }

      before do
        allow(publisher).to receive(:perform_purge?).and_return(true)
      end

      it "probabilistically purges old jobs" do
        publisher.publish

        expect(published_job).not_to have_been_destroyed
        expect(purgeable_job).to have_been_destroyed
      end
    end

    context "error handling" do
      let(:batch_size) { 3 }
      let(:logger) { SidekiqPublisher.logger }

      before do
        allow(SidekiqPublisher.logger).to receive(:warn)
      end

      shared_examples_for "an exception reporter is configured", :integration do
        let(:exception_reporter) { instance_double(Proc) }
        let(:instrumenter) { SidekiqPublisher::Instrumenter.new }

        before do
          allow(exception_reporter).to receive(:call)
          SidekiqPublisher.exception_reporter = exception_reporter
          allow(instrumenter).to receive(:instrument).with("error.publisher", instance_of(Hash)).and_call_original
        end

        it "reports the error to the exception reporter" do
          publisher.publish

          expect(exception_reporter).to have_received(:call).with(error)
        end
      end

      context "when an error is raised prior to publishing" do
        let(:error) { StandardError.new("something wrong") }

        before do
          allow(ActiveSupport::Inflector).to receive(:constantize).with("TestJobClass").and_raise(error)
        end

        it "does not raise an error" do
          expect { publisher.publish }.not_to raise_error
        end

        it "logs a warning" do
          publisher.publish

          expect(logger).to have_received(:warn)
        end

        it "instruments the error" do
          publisher.publish

          expect(instrumenter).to have_received(:instrument).
            with("error.publisher", exception_object: error, exception: [error.class.name, error.message])
        end

        it_behaves_like "an exception reporter is configured"

        it "does not update any jobs as published" do
          publisher.publish

          expect(job_model.unpublished.pluck(:id)).to match_array(unpublished_jobs.map(&:id))
        end
      end

      context "when an error is raised enqueueing to Sidekiq" do
        let(:error) { StandardError.new("something redis") }

        before do
          allow(client).to receive(:bulk_push).and_raise(error)
        end

        it "does not raise an error" do
          expect { publisher.publish }.not_to raise_error
        end

        it "logs a warning" do
          publisher.publish

          expect(logger).to have_received(:warn)
        end

        it "instruments the error" do
          publisher.publish

          expect(instrumenter).to have_received(:instrument).
            with("error.publisher", exception_object: error, exception: [error.class.name, error.message])
        end

        it_behaves_like "an exception reporter is configured"

        it "does not update any jobs as published" do
          publisher.publish

          expect(job_model.unpublished.pluck(:id)).to match_array(unpublished_jobs.map(&:id))
        end

        context "with a metrics reporter configured" do
          include_context "metrics_reporter context"

          it "does not record a count of jobs published" do
            publisher.publish

            expect(metrics_reporter).not_to have_received(:try)
          end
        end
      end

      context "when an error is raised while marking jobs as published" do
        let(:error) { StandardError.new("error during update") }

        before do
          first_call = true
          allow(job_model).to receive(:published!) do |job_ids|
            if first_call
              first_call = false
              raise(error)
            else
              # second call successed
              job_model.where(id: job_ids).update_all(published_at: Time.now.utc)
            end
          end
        end

        it "does not raise an error" do
          expect { publisher.publish }.not_to raise_error
        end

        it "logs a warning" do
          publisher.publish

          expect(logger).to have_received(:warn)
        end

        it "instruments the error" do
          publisher.publish

          expect(instrumenter).to have_received(:instrument).
            with("error.publisher", exception_object: error, exception: [error.class.name, error.message])
        end

        it_behaves_like "an exception reporter is configured"

        it "updates the status of each published job" do
          publisher.publish

          expect(job_model.published.pluck(:id)).to match_array(unpublished_jobs.map(&:id))
        end

        context "when an Exception is raised while marking jobs as published" do
          let(:error) { SignalException.new("TERM") }

          it "updates the status of each published job" do
            expect { publisher.publish }.to raise_error(error)

            expect(job_model.published.pluck(:id)).to match_array(unpublished_jobs.map(&:id))
          end
        end
      end
    end
  end
end
