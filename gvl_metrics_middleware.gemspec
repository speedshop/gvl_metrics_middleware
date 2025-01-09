# frozen_string_literal: true

require_relative "lib/gvl_metrics_middleware/version"

Gem::Specification.new do |spec|
  spec.name = "gvl_metrics_middleware"
  spec.version = GvlMetricsMiddleware::VERSION
  spec.authors = ["Yuki Nishijima"]
  spec.email = ["yuki@xpillars.software"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

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

  spec.add_development_dependency "activemodel" # Just to be able to run the tests.
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "appraisal", ">= 2.2"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "railties", ">= 7.1"
  spec.add_development_dependency "sidekiq"
end
