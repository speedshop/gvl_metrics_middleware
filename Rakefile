# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new("test") do |task|
  task.libs << "test"

  task.test_files = Dir["test/gvl_metrics_middleware/**/*_test.rb"]
  task.verbose = true
  task.warning = true
end

Rake::TestTask.new("test:isolated") do |task|
  task.libs << "test"

  task.test_files = ["test/isolated/**/*_test.rb"]
  task.verbose = true
  task.warning = true
end

task default: [:test, "test:isolated"]
