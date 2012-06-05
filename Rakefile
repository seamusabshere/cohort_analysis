#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake'
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :test_each_db_adapter do
  %w{ mysql sqlite postgresql }.each do |database|
    puts
    puts "#{'*'*10} Running tests with #{database}"
    puts
    puts `rake test DATABASE=#{database}`
  end
end

task :default => :test_each_db_adapter
task :spec => :test_each_db_adapter

require 'yard'
YARD::Rake::YardocTask.new
