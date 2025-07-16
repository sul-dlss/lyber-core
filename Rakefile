# frozen_string_literal: true

require 'rubygems'
require 'rake'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Dir.glob('lib/tasks/*.rake').each { |r| import r }

require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if File.exist? 'coverage.data'
end

task(:default).clear

task default: [:rubocop, :spec]
