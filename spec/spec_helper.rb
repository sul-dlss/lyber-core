$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'simplecov'
require 'coveralls'
Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::HTMLFormatter,
                                                                 Coveralls::SimpleCov::Formatter
                                                               ])
SimpleCov.start { add_filter 'spec/' }

require 'bundler/setup'
require 'rspec'
require 'lyber_core'

Rails = Object.new unless defined? Rails

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
