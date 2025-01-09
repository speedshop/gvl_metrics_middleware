# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new('test') do |task|
  task.libs << "test"

  task.test_files = Dir['test/**/*_test.rb']
  task.verbose = true
  task.warning = true
end

task default: :test
