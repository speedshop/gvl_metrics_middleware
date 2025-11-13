# frozen_string_literal: true

require "rails/railtie"

module GvlMetricsMiddleware
  class Railtie < Rails::Railtie
    config.gvl_metrics_middleware = ActiveSupport::OrderedOptions.new
    config.gvl_metrics_middleware.enabled = !Rails.env.test?
    config.gvl_metrics_middleware.safe_guard = Rails.env.production?

    initializer "gvl_metrics_middleware.rack" do |app|
      app.config.middleware.insert(0, GvlMetricsMiddleware::Rack)
    end

    config.after_initialize do |app|
      GvlMetricsMiddleware.enabled = app.config.gvl_metrics_middleware.enabled
      setup_safe_guard(app.config)
      configure_sidekiq_middleware(app.config)
    end

    def self.configure_sidekiq_middleware(app_config)
      if defined?(::Sidekiq) && app_config.gvl_metrics_middleware.enabled
        require "gvl_metrics_middleware/sidekiq"

        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.prepend(GvlMetricsMiddleware::Sidekiq)
          end
        end
      end
    end

    def self.setup_safe_guard(app_config)
      if app_config.gvl_metrics_middleware.enabled && app_config.gvl_metrics_middleware.safe_guard
        GvlMetricsMiddleware.on_report_failure.nil? && GvlMetricsMiddleware.on_report_failure do |source, exception|
          Rails.logger.error("GVL Metrics Middleware failed to report metrics from #{source}: #{exception.class} (#{exception.message})")
        end

        GvlMetricsMiddleware.safe_guard = app_config.gvl_metrics_middleware.safe_guard
      end
    end
  end
end
