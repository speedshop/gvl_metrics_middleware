# frozen_string_literal: true

module GvlMetricsMiddleware
  class Railtie < Rails::Railtie
    initializer "gvl_metrics_middleware.rack" do |app|
      app.config.middleware.insert(0, ::GvlMetricsMiddleware::Rack)
    end

    # initializer 'gvl_metrics.sidekiq' do |app|
    # end
    #
    # initializer 'gvl_metrics.active_job' do |app|
    # end
  end
end
