# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  setup do
    reset
  end

  test "#configure block allows for setting up a hook for Rack" do
    hook = ->(_total, _running, _io_wait, _gvl_wait) {
      # no-op...
    }

    GvlMetricsMiddleware.configure do |config|
      config.rack(&hook)
    end

    assert_same hook, GvlMetricsMiddleware::Rack.reporter
  end

  test "#configure block allows for setting up a hook for Sidekiq" do
    hook = ->(_total, _running, _io_wait, _gvl_wait) {
      # no-op...
    }

    GvlMetricsMiddleware.configure do |config|
      config.sidekiq(&hook)
    end

    assert_same hook, GvlMetricsMiddleware::Sidekiq.reporter
  end
end
