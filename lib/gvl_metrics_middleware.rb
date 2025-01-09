# frozen_string_literal: true

require_relative "gvl_metrics_middleware/version"
require "gvl_metrics_middleware/rack" if defined?(::Rack)
# require 'gvl_metrics_middleware/sidekiq' if defined?(::Sidekiq)
require "gvl_metrics_middleware/railtie" if defined?(::Rails)

module GvlMetricsMiddleware
  def self.rack_reporter(&block)
    if block_given?
      GvlMetricsMiddleware::Rack.reporter = block
    else
      GvlMetricsMiddleware::Rack.reporter
    end
  end
end
