# frozen_string_literal: true

RSpec.describe SidekiqPublisher::Runner, cleaner_strategy: :truncation do
  let(:timeout) { 60 }
  let(:counter) { Hash.new(0) }
  let(:publisher) { instance_double(SidekiqPublisher::Publisher) }
  let(:runner_thread) do
    Thread.new do
      begin
        described_class.run
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end
  end

  before do
    allow(publisher).to receive(:publish) { counter[:published] += 1 }
    allow(SidekiqPublisher::Publisher).to receive(:new).and_return(publisher)
    stub_const("#{described_class}::LISTENER_TIMEOUT_SECONDS", timeout)
    runner_thread
  end

  after do
    runner_thread.terminate
    runner_thread.join
  end

  it "publishes when the listener starts" do
    wait_for("start") { counter[:published] > 0 }

    expect(publisher).to have_received(:publish)
  end

  it "publishes when the listener is notified" do
    wait_for("start") { counter[:published] > 0 }
    create(:publisher_job)
    wait_for("notify") { counter[:published] > 1 }

    expect(publisher).to have_received(:publish).twice
  end

  context "when the notification times out" do
    let(:timeout) { 0.1 }

    before do
      allow(SidekiqPublisher::Job).to receive(:purge_expired_published!) do
        counter[:purged] += 1
      end
    end

    it "purges old, published jobs" do
      wait_for("start") { counter[:published] > 0 }
      wait_for("purge") { counter[:purged] > 0 }

      expect(SidekiqPublisher::Job).to have_received(:purge_expired_published!)
    end

    context "when there are unpublished jobs" do
      before do
        allow(SidekiqPublisher.logger).to receive(:warn)
        # rubocop:disable RSpec/MessageChain
        allow(SidekiqPublisher::Job).to receive_message_chain(:unpublished, :exists?).and_return(true)
        # rubocop:enable RSpec/MessageChain
      end

      it "publishes unpublished jobs" do
        wait_for("start") { counter[:published] > 0 }
        wait_for("timeout") { counter[:published] > 1 }

        expect(SidekiqPublisher::Job).not_to have_received(:purge_expired_published!)
        expect(publisher).to have_received(:publish).at_least(:twice)
      end

      it "logs a warning message" do
        wait_for("start") { counter[:published] > 0 }
        wait_for("timeout") { counter[:published] > 1 }

        expect(SidekiqPublisher.logger).to have_received(:warn).with(
          "SidekiqPublisher::Runner: msg='publishing pending jobs at timeout'"
        )
      end
    end
  end

  def wait_for(notification)
    timeout_at = Time.now + 5
    loop do
      return if yield
      raise "Timed out waiting for #{notification}" if Time.now > timeout_at
      sleep(0.001)
    end
  end
end
