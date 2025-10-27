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

  test "sampling_rate can be set and retrieved" do
    GvlMetricsMiddleware.sampling_rate = 0.5
    assert_equal 0.5, GvlMetricsMiddleware.sampling_rate
  end

  test "sampling_rate defaults to 0.01" do
    assert_equal 0.01, GvlMetricsMiddleware.sampling_rate
  end

  test "sampling_rate raises error for values outside 0.0-1.0 range" do
    assert_raises(ArgumentError) { GvlMetricsMiddleware.sampling_rate = -0.1 }
    assert_raises(ArgumentError) { GvlMetricsMiddleware.sampling_rate = 1.1 }
  end

  test "sampling_rate converts string values to float" do
    GvlMetricsMiddleware.sampling_rate = "0.25"
    assert_equal 0.25, GvlMetricsMiddleware.sampling_rate
  end

  test "should_sample? returns true when sampling_rate is 1.0" do
    GvlMetricsMiddleware.sampling_rate = 1.0
    assert GvlMetricsMiddleware.should_sample?
  end

  test "should_sample? returns false when sampling_rate is 0.0" do
    GvlMetricsMiddleware.sampling_rate = 0.0
    refute GvlMetricsMiddleware.should_sample?
  end

  test "should_sample? respects sampling rate probabilistically" do
    GvlMetricsMiddleware.sampling_rate = 0.5

    samples = 1000.times.map { GvlMetricsMiddleware.should_sample? }
    true_count = samples.count(true)

    assert_operator true_count, :>, 400
    assert_operator true_count, :<, 600
  end

  test "#configure block allows for setting sampling_rate" do
    GvlMetricsMiddleware.configure do |config|
      config.sampling_rate = 0.3
    end

    assert_equal 0.3, GvlMetricsMiddleware.sampling_rate
  end
end
