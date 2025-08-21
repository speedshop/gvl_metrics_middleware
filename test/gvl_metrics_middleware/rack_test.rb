# frozen_string_literal: true

require "test_helper"
require "gvl_metrics_middleware/rack"

class RackMiddlewareTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @captured_value = []
  end

  teardown do
    @captured_value.clear
  end

  test "Custom hook gets called with GVL metrics" do
    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    get "/"

    total, running, io_wait, gvl_wait = @captured_value[0].map { _1 / 1_000_000_000 }

    assert_equal 1, total
    assert_equal 0, running
    assert_equal 1, io_wait
    assert_equal 0, gvl_wait
  end

  test "on_report_failure gets called on a failure" do
    name, exception = nil

    GvlMetricsMiddleware.safe_guard = true
    GvlMetricsMiddleware.on_report_failure do |the_name, the_exception|
      name, exception = the_name, the_exception
    end

    GvlMetricsMiddleware::Rack.reporter = ->(_total, _running, _io_wait, _gvl_wait) {
      raise "boom!"
    }

    get "/"

    assert_equal "Rack", name
    assert_equal RuntimeError, exception.class
    assert_equal "boom!", exception.message
  end

  private

  def app
    GvlMetricsMiddleware::Rack.new(->(_env) {
      sleep 1

      [200, {}, ["Test"]]
    })
  end
end
