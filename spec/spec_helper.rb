# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter 'spec/'
  add_filter 'lib/lyber_core/boot.rb'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bundler/setup'
require 'rspec'
require 'lyber_core'
require 'byebug'
require 'config'

LyberCore::Boot.new(File.expand_path('config', __dir__)).boot_config
