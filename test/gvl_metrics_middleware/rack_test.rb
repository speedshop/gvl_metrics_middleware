# frozen_string_literal: true

require "test_helper"
require "gvl_metrics_middleware/rack"

class RackMiddlewareTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @captured_value = []

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }
  end

  teardown do
    @captured_value.clear
  end

  test "#configure block allows for setting up a hook for Rack" do
    get "/"

    total, running, io_wait, gvl_wait = @captured_value[0].map { _1 / 1_000_000_000 }

    assert_equal 1, total
    assert_equal 0, running
    assert_equal 1, io_wait
    assert_equal 0, gvl_wait
  end

  private

  def app
    GvlMetricsMiddleware::Rack.new(->(_env) {
      sleep 1

      [200, {}, ["Test"]]
    })
  end
end
