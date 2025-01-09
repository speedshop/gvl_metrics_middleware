# frozen_string_literal: true

require "gvl_timing"

module GvlMetricsMiddleware
  class Rack
    @@reporter = nil

    class << self
      def reporter = @@reporter

      def reporter=(reporter)
        @@reporter = reporter
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      response = nil

      gvl_times = GVLTiming.measure do
        response = @app.call(env)
      end

      begin
        self.class.reporter&.call(gvl_times.duration_ns, gvl_times.running_duration_ns, gvl_times.idle_duration_ns, gvl_times.stalled_duration_ns)
      rescue => exception
        GvlMetricsMiddleware.on_report_failure&.call("Rack", exception)

        raise(exception) unless GvlMetricsMiddleware.safe_guard?
      end

      response
    end
  end
end
