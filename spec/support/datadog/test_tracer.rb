# frozen_string_literal: true

require "datadog/tracing/tracer"

module Datadog
  class TestTracer < Tracing::Tracer
    attr_reader :traces

    def initialize
      @traces = Array.new
      super(enabled: true)
      configure(transport_options: proc { |t| t.adapter :test })
    end

    def reset!
      @traces.clear
    end

    def write(trace)
      @traces << trace
      super
    end
  end
end
