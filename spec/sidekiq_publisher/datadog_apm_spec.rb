# frozen_string_literal: true

RSpec.describe SidekiqPublisher::DatadogAPM do
  test_tracer_class = begin
                        Datadog::Tracing::Tracer
                      rescue NameError
                        Datadog::Tracer
                      end

  class TestTracer < test_tracer_class # rubocop:disable RSpec/LeakyConstantDeclaration
    attr_reader :traces

    def initialize(*)
      super

      @traces = []
    end

    def write(trace)
      @traces << trace # rubocop:disable RSpec/InstanceVariable
      super
    end
  end

  let(:instrumenter) { SidekiqPublisher::Instrumenter.new }
  let(:service) { "sidekiq-publisher" }
  let(:span) { tracer_instance.traces.first.spans.first }
  let(:tracer_instance) { TestTracer.new }

  before do
    Datadog.configure do |c|
      if c.respond_to?(:tracing)
        c.tracing.instance = tracer_instance
      else
        c.tracer = tracer_instance
      end
    end
  end

  describe ".service" do
    context "when unset" do
      it "returns sidekiq-publisher" do
        expect(described_class.service).to eq("sidekiq-publisher")
      end
    end

    context "when set" do
      let(:service) { "test-sidekiq-publisher" }

      before { described_class.service = service }

      after { described_class.service = nil }

      it "returns the configured service" do
        expect(described_class.service).to eq(service)
      end
    end
  end

  shared_examples_for "trace error handling" do |event_name|
    let!(:error) { RuntimeError.new(SecureRandom.uuid) }

    it "adds any error to the #{event_name} span" do
      begin
        instrumenter.instrument(event_name) do
          raise error
        end
      rescue StandardError
        nil
      end

      expect(span).to have_error(error)
    end
  end

  describe "ListenerSubscriber" do
    it "creates a span for a listener.timeout resource" do
      instrumenter.instrument("timeout.listener") {}
      expect(span.service).to eq(service)
      expect(span.name).to eq("sidekiq_publisher")
      expect(span.resource).to eq("listener.timeout")
    end

    it_behaves_like "trace error handling", "timeout.listener"
  end

  describe "RunnerSubscriber" do
    it "creates a span for a publisher.start resource" do
      instrumenter.instrument("start.publisher") {}
      expect(span.service).to eq(service)
      expect(span.name).to eq("sidekiq_publisher")
      expect(span.resource).to eq("publisher.start")
    end

    it "creates a span for a publisher.notify resource" do
      instrumenter.instrument("notify.publisher") {}
      expect(span.service).to eq(service)
      expect(span.name).to eq("sidekiq_publisher")
      expect(span.resource).to eq("publisher.notify")
    end

    it "creates a span for a publisher.timeout resource" do
      instrumenter.instrument("timeout.publisher") {}
      expect(span.service).to eq(service)
      expect(span.name).to eq("sidekiq_publisher")
      expect(span.resource).to eq("publisher.timeout")
    end

    it_behaves_like "trace error handling", "start.publisher"
    it_behaves_like "trace error handling", "notify.publisher"
    it_behaves_like "trace error handling", "timeout.publisher"
  end

  describe "PublisherSubscriber" do
    it "creates a span for a publisher.publish_batch operation" do
      instrumenter.instrument("publish_batch.publisher") {}
      expect(span.service).to eq(service)
      expect(span.name).to eq("publisher.publish_batch")
    end

    it "creates a span for a publisher.enqueue_batch operation" do
      published_count = rand(1..100)
      instrumenter.instrument("publish_batch.publisher") do
        instrumenter.instrument("enqueue_batch.publisher") do |notification|
          notification[:published_count] = published_count
        end
      end
      expect(span).to have_tag(:published_count).with_value(published_count)
      expect(span.service).to eq(service)
      expect(span.name).to eq("publisher.enqueue_batch")
    end

    it_behaves_like "trace error handling", "publish_batch.publisher"
    it_behaves_like "trace error handling", "enqueue_batch.publisher"
  end

  describe "PublisherErrorSubscriber" do
    let(:error) { RuntimeError.new("boom") }
    let(:payload) { { exception_object: error, exception: [error.class.name, error.message] } }

    it "adds an error to the current span" do
      described_class.tracer.trace("example") do
        instrumenter.instrument("error.publisher", payload)
      end

      expect(span).to have_error(error)
    end
  end

  describe "JobSubscriber" do
    it "creates a span for a job.purge operation" do
      purged_count = rand(1..100)
      instrumenter.instrument("purge.job") do |notification|
        notification[:purged_count] = purged_count
      end

      expect(span).to have_tag(:purged_count).with_value(purged_count)
      expect(span.service).to eq(service)
      expect(span.name).to eq("job.purge")
    end

    it_behaves_like "trace error handling", "purge.job"
  end

  matcher :have_tag do |name|
    match do |span|
      tag = span.get_tag(name.to_s)
      values_match?(value, tag)
    end

    chain :with_value, :value

    failure_message do
      "expected span to have tag #{expected} with value #{value}"
    end
  end

  matcher :have_error do |expected|
    attr_accessor :error_type, :error_msg

    match do |span|
      self.error_type = span.get_tag("error.type")
      self.error_msg = span.get_tag("error.message")
      values_match?(expected.class.name, error_type) && values_match?(expected.message, error_msg)
    end

    failure_message do
      "expected span to have error #{expected.inspect} got #<#{error_type}: #{error_msg}>"
    end
  end
end
