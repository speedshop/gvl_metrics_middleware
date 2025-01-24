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

  def setup
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add GvlMetricsMiddleware::Sidekiq
    end

    @captured_value = []

    GvlMetricsMiddleware::Sidekiq.reporter = ->(total, running, io_wait, gvl_wait) {
      @captured_value << [total, running, io_wait, gvl_wait]
    }
  end

  def teardown
    Sidekiq::Testing.disable!
  end

  def test_custom_middleware_adds_header
    TestWorker.perform_async

    total, running, io_wait, gvl_wait = @captured_value[0].map { _1 / 1_000_000_000 }

    assert_equal 1, total
    assert_equal 0, running
    assert_equal 1, io_wait
    assert_equal 0, gvl_wait
  end
end
