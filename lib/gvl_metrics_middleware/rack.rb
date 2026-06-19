# frozen_string_literal: true

require "gvl_timing"

module GvlMetricsMiddleware
  class Rack
    @@reporter = nil

    class << self
      def reporter = @@reporter

      def reporter=(reporter)
        @@reporter = reporter
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      reporter = self.class.reporter
      return @app.call(env) if reporter.nil? || !GvlMetricsMiddleware.should_sample?

      response = nil

      gvl_times = GVLTiming.measure do
        response = @app.call(env)
      end

      begin
        reporter.call(gvl_times.duration_ns, gvl_times.running_duration_ns, gvl_times.idle_duration_ns, gvl_times.stalled_duration_ns, route: route_for(env))
      rescue => exception
        GvlMetricsMiddleware.on_report_failure&.call("Rack", exception)

        raise(exception) unless GvlMetricsMiddleware.safe_guard?
      end

      response
    end

    private

    # The request's route template, passed to the reporter so it can segment GVL
    # metrics by endpoint (for example, the CPU/IO ratio per action). On Rails it
    # is the "controller#action" pair; on Sinatra it is the matched route. Only the
    # route *template* is used -- never the raw path -- so it stays low-cardinality,
    # and on Rails only :controller and :action are read (path_parameters also holds
    # :id, :format, ...). Returns nil when no route matched (404s, or a plain Rack
    # app), leaving any fallback to the reporter.
    def route_for(env)
      if (path_parameters = env["action_dispatch.request.path_parameters"]) # Rails
        controller = path_parameters[:controller]
        action = path_parameters[:action]
        return "#{controller}##{action}" if controller && action
      end

      env["sinatra.route"] # Sinatra, e.g. "GET /users/:id"
    end
  end
end
