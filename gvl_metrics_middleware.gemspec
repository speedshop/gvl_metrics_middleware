# frozen_string_literal: true

require_relative "lib/gvl_metrics_middleware/version"

Gem::Specification.new do |spec|
  spec.name = "gvl_metrics_middleware"
  spec.version = GvlMetricsMiddleware::VERSION
  spec.authors = ["Nate Berkopec", "Yuki Nishijima"]
  spec.email = ["nate.berkopec@speedshop.co", "yuki.nishijima@speedshop.co"]

  spec.summary = "Rack and Sidekiq middlewares for GVL metrics"
  spec.description = "gvl_metrics_middlewareprovides Rack and Sidekiq middlewares for GVL metrics"
  spec.homepage = "https://github.com/speedshop/gvl_metrics_middleware"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/speedshop/gvl_metrics_middleware"
  spec.metadata["changelog_uri"] = "https://github.com/speedshop/gvl_metrics_middleware/releases"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "gvl_timing"

  spec.add_development_dependency "appraisal", ">= 2.2"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "sidekiq"
end
