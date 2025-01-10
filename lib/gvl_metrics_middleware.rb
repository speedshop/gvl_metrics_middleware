# frozen_string_literal: true

require_relative "gvl_metrics_middleware/version"
require "gvl_metrics_middleware/rack" if defined?(::Rack)
require "gvl_metrics_middleware/sidekiq" if defined?(::Sidekiq)
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
    if block_given?
      GvlMetricsMiddleware::Sidekiq.reporter = block
    else
      GvlMetricsMiddleware::Sidekiq.reporter
    end
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
end
