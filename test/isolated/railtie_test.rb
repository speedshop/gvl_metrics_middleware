# frozen_string_literal: true

require "test_in_isolation_helper"
require "minitest/mock"

class RailtieTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation
  include Rack::Test::Methods
  include Generation

  setup do
    build_app
    FileUtils.rm_rf "#{app_path}/config/environments"
  end

  teardown do
    teardown_app
  end

  test "inserts the GVL metrics rack middleware to the very beginning when enabled" do
    boot_rails

    assert_equal "GvlMetricsMiddleware::Rack", app.config.middleware[0].name
  end

  test "does not insert the rack middleware when disabled" do
    add_to_config <<-RUBY
      config.gvl_metrics_middleware.enabled = false
    RUBY

    boot_rails

    assert !GvlMetricsMiddleware.enabled?, "Expected GvlMetricsMiddleware to be disabled"
    assert !GvlMetricsMiddleware.should_sample?, "Expected GvlMetricsMiddleware to not sample"
  end

  test "allows rack middleware configuration in initializers before middleware is added" do
    add_initializer "gvl_config", <<-RUBY
      Rails.application.configure do
        config.gvl_metrics_middleware.enabled = false
      end
    RUBY

    boot_rails

    assert !GvlMetricsMiddleware.enabled?, "Expected GvlMetricsMiddleware to be disabled"
    assert !GvlMetricsMiddleware.should_sample?, "Expected GvlMetricsMiddleware to not sample"
  end

  test "works with the rack-attack gem" do
    add_initializer "rack_attack", <<-RUBY
      DUMMY_MIDDLEWARE = Class.new do
        def initialize(app) = @app = app
        def call(env) = @app.call(env)
      end

      Rails.application.config.middleware.insert_after(Rack::Attack, DUMMY_MIDDLEWARE)
    RUBY

    boot_rails

    assert_includes app.config.middleware.map(&:name), "Rack::Attack"
    assert_includes app.config.middleware.map(&:name), "DUMMY_MIDDLEWARE"
  end

  test "inserts the sidekiq middleware to the very beginning when enabled on server" do
    add_to_config <<-RUBY
      GvlMetricsMiddleware.configure do |config|
        config.sidekiq do |_total, _running, _io_wait, _gvl_wait|
          # no-op...
        end
      end
    RUBY

    Sidekiq.stub :server?, true do
      boot_rails
    end

    assert_equal "GvlMetricsMiddleware::Sidekiq", Sidekiq.default_configuration.server_middleware.to_a[0].klass.name
  end

  test "does not insert the sidekiq middleware on the client (e.g. web server is a sidekiq client)" do
    add_to_config <<-RUBY
      config.gvl_metrics_middleware.enabled = true
    RUBY

    Sidekiq.stub :server?, false do
      boot_rails
    end

    assert_not_includes Sidekiq.default_configuration.server_middleware.map(&:klass).map(&:name), "GvlMetricsMiddleware::Sidekiq"
  end

  test "does not insert the sidekiq middleware when disabled" do
    add_to_config <<-RUBY
      config.gvl_metrics_middleware.enabled = false
    RUBY

    boot_rails

    assert_not_includes Sidekiq.default_configuration.server_middleware.map(&:klass).map(&:name), "GvlMetricsMiddleware::Sidekiq"
  end

  test "allows sidekiq middleware configuration in initializers before middleware is added" do
    add_initializer "gvl_config", <<-RUBY
      Rails.application.configure do
        config.gvl_metrics_middleware.enabled = false
      end
    RUBY

    Sidekiq.stub :server?, true do
      boot_rails
    end

    assert_not_includes Sidekiq.default_configuration.server_middleware.map(&:klass).map(&:name), "GvlMetricsMiddleware::Sidekiq"
  end

  test "does not add a safe guard when set to false" do
    boot_rails

    assert !app.config.gvl_metrics_middleware.safe_guard, "Expected safe guard to be disabled"
    assert !GvlMetricsMiddleware.safe_guard?, "Expected safe guard to be disabled"
    assert_nil GvlMetricsMiddleware.on_report_failure
  end

  test "adds a safe guard when set to true" do
    add_to_config <<-RUBY
      config.gvl_metrics_middleware.safe_guard = true
    RUBY

    boot_rails

    assert app.config.gvl_metrics_middleware.safe_guard, "Expected safe guard to be enabled"
    assert GvlMetricsMiddleware.safe_guard?, "Expected safe guard to be enabled"
    assert_not_nil GvlMetricsMiddleware.on_report_failure
  end

  private

  def app = Rails.application

  def boot_rails
    require "#{app_path}/config/environment"
  end
end
