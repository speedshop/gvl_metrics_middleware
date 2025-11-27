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

    def call(job_instance, _job_payload, queue)
      reporter = self.class.reporter
      return yield if reporter.nil? || !GvlMetricsMiddleware.should_sample?

      gvl_times = GVLTiming.measure { yield }

      begin
        reporter.call(gvl_times.duration_ns, gvl_times.running_duration_ns, gvl_times.idle_duration_ns, gvl_times.stalled_duration_ns, job_class: job_instance.class.to_s, queue: queue)
      rescue => exception
        GvlMetricsMiddleware.on_report_failure&.call("Sidekiq", exception)

        raise(exception) unless GvlMetricsMiddleware.safe_guard?
      end
    end
  end
end
