# frozen_string_literal: true

require "test_helper"
require "sidekiq/testing"
require "gvl_metrics_middleware/sidekiq"

class SidekiqMiddlewareTest < ActiveSupport::TestCase
  class TestWorker
    include Sidekiq::Worker

    def perform(*args)
      sleep 1
    end
  end

  setup do
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add GvlMetricsMiddleware::Sidekiq
    end
  end

  teardown do
    Sidekiq::Testing.disable!
  end

  test "Custom hook gets called with GVL metrics" do
    captured_value = []

    GvlMetricsMiddleware::Sidekiq.reporter = ->(total, running, io_wait, gvl_wait, **options) {
      captured_value << [total, running, io_wait, gvl_wait, options]
    }

    TestWorker.perform_async

    total, running, io_wait, gvl_wait = captured_value[0].first(4).map { _1 / 1_000_000_000 }
    options = captured_value[0][4]

    assert_equal 1, total
    assert_equal 0, running
    assert_equal 1, io_wait
    assert_equal 0, gvl_wait
    assert_equal [:job_class, :queue], options.keys
    assert_equal "SidekiqMiddlewareTest::TestWorker", options[:job_class]
    assert_equal "default", options[:queue]
  end

  test "on_report_failure gets called on a failure" do
    name, exception = nil

    GvlMetricsMiddleware.safe_guard = true
    GvlMetricsMiddleware.on_report_failure do |the_name, the_exception|
      name, exception = the_name, the_exception
    end

    GvlMetricsMiddleware::Sidekiq.reporter = proc { |_total, _running, _io_wait, _gvl_wait|
      raise "boom!"
    }

    TestWorker.perform_async

    assert_equal "Sidekiq", name
    assert_equal RuntimeError, exception.class
    assert_equal "boom!", exception.message
  end
end
