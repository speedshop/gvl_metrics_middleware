# frozen_string_literal: true

require "rails/railtie"

module GvlMetricsMiddleware
  class Railtie < Rails::Railtie
    config.gvm_metrics_middleware = ActiveSupport::OrderedOptions.new
    config.gvm_metrics_middleware.enabled = !Rails.env.test?

    initializer "gvl_metrics_middleware.rack" do |app|
      app.config.middleware.insert(0, GvlMetricsMiddleware::Rack) if app.config.gvm_metrics_middleware.enabled
    end

    initializer "gvl_metrics_middleware.sidekiq" do |app|
      if app.config.gvm_metrics_middleware.enabled
        ::Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.prepend(GvlMetricsMiddleware::Sidekiq)
          end
        end
      end
    end

    config.after_initialize do |app|
      setup_logger_for_report_failures if app.config.gvm_metrics_middleware.enabled
    end

    def setup_logger_for_report_failures
      GvlMetricsMiddleware.on_report_failure.nil? && GvlMetricsMiddleware.on_report_failure do |source, exception|
        Rails.logger.error("GVL Metrics Middleware failed to report metrics from #{source}: #{exception.class} (#{exception.message})")
      end
    end
  end
end
