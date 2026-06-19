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

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait, **) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    get "/"

    total, running, io_wait, gvl_wait = @captured_value[0].map { (_1.to_f / 1_000_000_000).round(3) }

    assert_operator total, :<=, 0.002
    assert_operator running, :<=, 0.002
    assert_operator io_wait, :<=, 0.002
    assert_operator gvl_wait, :<=, 0.002
  end

  test "on_report_failure gets called on a failure" do
    GvlMetricsMiddleware.sampling_rate = 1.0
    name, exception = nil

    GvlMetricsMiddleware.safe_guard = true
    GvlMetricsMiddleware.on_report_failure do |the_name, the_exception|
      name, exception = the_name, the_exception
    end

    GvlMetricsMiddleware::Rack.reporter = ->(_total, _running, _io_wait, _gvl_wait, **) {
      raise "boom!"
    }

    get "/"

    assert_equal "Rack", name
    assert_equal RuntimeError, exception.class
    assert_equal "boom!", exception.message
  end

  test "middleware skips GVL measurement when sampling rate is 0.0" do
    GvlMetricsMiddleware.sampling_rate = 0.0

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait, **) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    get "/"

    assert_empty @captured_value
  end

  test "middleware always measures when sampling rate is 1.0" do
    GvlMetricsMiddleware.sampling_rate = 1.0

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait, **) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    100.times { get "/" }

    assert_equal 100, @captured_value.length
  end

  test "middleware respects sampling rate probabilistically" do
    GvlMetricsMiddleware.sampling_rate = 0.5

    GvlMetricsMiddleware::Rack.reporter = ->(total, running, io_wait, gvl_wait, **) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }

    100.times { get "/" }

    assert_operator @captured_value.length, :>=, 25
    assert_operator @captured_value.length, :<=, 75
  end

  test "middleware skips when no reporter configured" do
    GvlMetricsMiddleware.sampling_rate = 1.0
    GvlMetricsMiddleware::Rack.reporter = nil

    measure_called = false
    stub_proc = proc { measure_called = true }
    GVLTiming.stub(:measure, stub_proc) do
      get "/"
    end

    assert_not measure_called
  end

  test "reporter receives the Rails controller#action as route" do
    GvlMetricsMiddleware.sampling_rate = 1.0
    GvlMetricsMiddleware::Rack.reporter = ->(_total, _running, _io_wait, _gvl_wait, **options) {
      @captured_value << options
    }
    @inner_app = ->(env) {
      env["action_dispatch.request.path_parameters"] = { controller: "admin/users", action: "index" }
      [200, {}, ["ok"]]
    }

    get "/admin/users"

    assert_equal "admin/users#index", @captured_value[0][:route]
  end

  test "reporter receives the Sinatra route as route" do
    GvlMetricsMiddleware.sampling_rate = 1.0
    GvlMetricsMiddleware::Rack.reporter = ->(_total, _running, _io_wait, _gvl_wait, **options) {
      @captured_value << options
    }
    @inner_app = ->(env) {
      env["sinatra.route"] = "GET /users/:id"
      [200, {}, ["ok"]]
    }

    get "/users/1"

    assert_equal "GET /users/:id", @captured_value[0][:route]
  end

  test "reporter receives a nil route when no route matched" do
    GvlMetricsMiddleware.sampling_rate = 1.0
    GvlMetricsMiddleware::Rack.reporter = ->(_total, _running, _io_wait, _gvl_wait, **options) {
      @captured_value << options
    }
    @inner_app = ->(_env) { [404, {}, ["not found"]] }

    get "/nope"

    assert_nil @captured_value[0][:route]
  end

  private

  def app
    GvlMetricsMiddleware::Rack.new(@inner_app || default_inner_app)
  end

  def default_inner_app
    ->(_env) {
      sleep 0.001

      [200, {}, ["Test"]]
    }
  end
end
