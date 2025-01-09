# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "active_support"
require "active_support/core_ext/kernel/reporting"
require "active_support/deprecation"
require "active_support/testing/autorun"

require "rack/test"

require "minitest/pride"
require "rails/version"
require "rails"
require "rails/railtie"
require "sidekiq"

require "active_support/testing/method_call_assertions"
ActiveSupport::TestCase.include ActiveSupport::Testing::MethodCallAssertions

module Paths
  def app_template_path
    File.join Dir.tmpdir, "app_template"
  end

  def tmp_path(*args)
    @tmp_path ||= File.realpath(Dir.mktmpdir)
    File.join(@tmp_path, *args)
  end

  def app_path(*args)
    tmp_path(*%w[app] + args)
  end
end

module Generation
  extend Paths
  include Paths

  # Build an application by invoking the generator and going through the whole stack.
  def build_app(options = {})
    @prev_rails_env = ENV["RAILS_ENV"]
    ENV["RAILS_ENV"] = "development"
    ENV["SECRET_KEY_BASE"] ||= SecureRandom.hex(16)

    FileUtils.rm_rf(app_path)
    FileUtils.cp_r(app_template_path, app_path)

    # Delete the initializers unless requested
    unless options[:initializers]
      Dir["#{app_path}/config/initializers/**/*.rb"].each do |initializer|
        File.delete(initializer)
      end
    end

    add_to_config <<-RUBY
      config.eager_load = false
      config.session_store :cookie_store, key: "_myapp_session"
      config.active_support.deprecation = :log
      config.active_support.test_order = :random
      config.action_controller.allow_forgery_protection = false
      config.log_level = :info
    RUBY
  end

  def teardown_app
    ENV["RAILS_ENV"] = @prev_rails_env if @prev_rails_env
    FileUtils.rm_rf(tmp_path)
  end

  def add_to_config(str)
    environment = File.read("#{app_path}/config/application.rb")
    if environment =~ /(\n\s*end\s*end\s*)\z/
      File.open("#{app_path}/config/application.rb", "w") do |f|
        f.puts $` + "\n#{str}\n" + $1
      end
    end
  end

  def self.initialize_app
    FileUtils.rm_rf(app_template_path)
    FileUtils.mkdir(app_template_path)

    `rails new #{app_template_path} --skip-gemfile --skip-action-cable --skip-active-storage --skip-active-record ---skip-activemodel --skip-active-job --skip-sprockets --skip-javascript --skip-listen --no-rc`

    File.open("#{app_template_path}/config/boot.rb", "w")
  end
end

Generation.initialize_app

require "gvl_metrics_middleware"
