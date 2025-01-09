# frozen_string_literal: true

require "gvl_timing"
require "sidekiq/middleware/modules"

module GvlMetricsMiddleware
  class Sidekiq
    @@reporter = nil

    class << self
      def reporter = @@reporter

      def reporter=(reporter)
        @@reporter = reporter
      end
    end

    include ::Sidekiq::ServerMiddleware

    def call(_job_instance, _job_payload, _queue)
      gvl_times = GVLTiming.measure { yield }

      begin
        self.class.reporter&.call(gvl_times.duration_ns, gvl_times.running_duration_ns, gvl_times.idle_duration_ns, gvl_times.stalled_duration_ns)
      rescue => exception
        GvlMetricsMiddleware.on_report_failure&.call("Sidekiq", exception)
      end
    end
  end
end
