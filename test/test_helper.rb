# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "active_support/test_case"
require "active_support/testing/autorun"

require "rails/version"
require "rails"
require "rails/railtie"
require "sidekiq"

require "gvl_metrics_middleware"

class ActiveSupport::TestCase
  private

  def reset
    GvlMetricsMiddleware::Rack.reporter = nil
    GvlMetricsMiddleware::Sidekiq.reporter = nil
  end
end
