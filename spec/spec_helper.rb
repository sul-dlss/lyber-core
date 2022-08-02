# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'simplecov'

SimpleCov.start { add_filter 'spec/' }

require 'bundler/setup'
require 'rspec'
require 'lyber_core'

Rails = Object.new unless defined? Rails

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
