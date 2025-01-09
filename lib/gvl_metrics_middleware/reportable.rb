# frozen_string_literal: true

module GvlMetricsMiddleware
  @@reporter = nil

  class << self
    def reporter = @@reporter

    def reporter=(reporter)
      @@reporter = reporter
    end
  end

  def measure_and_report_gvl_timing(name)
    result = nil

    gvl_times = GVLTiming.measure do
      result = yield
    end

    begin
      gvl_timing_reporter&.call(gvl_times.duration_ns, gvl_times.running_duration_ns, gvl_times.idle_duration_ns, gvl_times.stalled_duration_ns)
    rescue => exception
      on_report_failure(exception)
    end

    result
  end
end
