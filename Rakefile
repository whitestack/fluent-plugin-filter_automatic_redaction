require "bundler/gem_tasks"
require 'rake/testtask'
  Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/plugin/test_filter_your_own.rb'
  test.verbose = true
end
task :default => :spec