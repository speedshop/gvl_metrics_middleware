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
    GvlMetricsMiddleware.sampling_rate = 1.0

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    get "/"

    total, running, io_wait, gvl_wait = @captured_value[0].map { (_1.to_f / 1_000_000_000).round(3) }

    assert_equal 0.001, total
    assert_equal 0, running
    assert_equal 0.001, io_wait
    assert_equal 0, gvl_wait
  end

  test "on_report_failure gets called on a failure" do
    GvlMetricsMiddleware.sampling_rate = 1.0
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

  test "middleware skips GVL measurement when sampling rate is 0.0" do
    GvlMetricsMiddleware.sampling_rate = 0.0

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    get "/"

    assert_empty @captured_value
  end

  test "middleware always measures when sampling rate is 1.0" do
    GvlMetricsMiddleware.sampling_rate = 1.0

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    100.times { get "/" }

    assert_equal 100, @captured_value.length
  end

  test "middleware respects sampling rate probabilistically" do
    GvlMetricsMiddleware.sampling_rate = 0.5

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    100.times { get "/" }

    assert_operator @captured_value.length, :>, 40
    assert_operator @captured_value.length, :<, 60
  end

  private

  def app
    GvlMetricsMiddleware::Rack.new(->(_env) {
      sleep 0.001

      [200, {}, ["Test"]]
    })
  end
end
