# frozen_string_literal: true

require_relative "gvl_metrics_middleware/version"
require "gvl_metrics_middleware/rack"
require "gvl_metrics_middleware/railtie" if defined?(::Rails)

module GvlMetricsMiddleware
  def self.configure = yield(self)

  def self.rack(&block)
    if block_given?
      GvlMetricsMiddleware::Rack.reporter = block
    else
      GvlMetricsMiddleware::Rack.reporter
    end
  end

  def self.sidekiq(&block)
    require "gvl_metrics_middleware/sidekiq"

    if block_given?
      GvlMetricsMiddleware::Sidekiq.reporter = block
    else
      GvlMetricsMiddleware::Sidekiq.reporter
    end
  end

  @@enabled = true

  def self.enabled? = @@enabled

  def self.enabled=(value)
    @@enabled = value
  end

  @@on_report_failure = nil

  def self.on_report_failure(&block)
    if block_given?
      @@on_report_failure = block
    else
      @@on_report_failure
    end
  end

  @@safe_guard = nil

  def self.safe_guard? = @@safe_guard

  def self.safe_guard=(value)
    @@safe_guard = value
  end

  @@sampling_rate = 0.01

  def self.sampling_rate
    @@sampling_rate
  end

  def self.sampling_rate=(rate)
    rate = rate.to_f
    if rate < 0.0 || rate > 1.0
      raise ArgumentError, "sampling_rate must be between 0.0 and 1.0, got #{rate}"
    end

    @@sampling_rate = rate
  end

  def self.should_sample?
    return true if @@sampling_rate == 1.0
    return false if @@sampling_rate == 0.0

    enabled? && (rand < @@sampling_rate)
  end
end
