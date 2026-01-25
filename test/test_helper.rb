# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "active_support"
require "active_support/test_case"
require "active_support/testing/autorun"

require "minitest/pride"
require "minitest/mock"
require "rails/version"
require "rails"
require "rails/railtie"
require "sidekiq"

# Monkey-patch Sidekiq < 6.5.0 to provide default_configuration for tests
if !Sidekiq.respond_to?(:default_configuration) && defined?(Sidekiq::VERSION)
  module Sidekiq
    def self.default_configuration
      @default_configuration ||= Struct.new(:server_middleware).new(Sidekiq.server_middleware)
    end
  end
end

require "gvl_metrics_middleware"

class ActiveSupport::TestCase
  private

  def reset
    GvlMetricsMiddleware.sampling_rate = 0.01
    GvlMetricsMiddleware::Rack.reporter = nil
    GvlMetricsMiddleware::Sidekiq.reporter = nil
  end
end
