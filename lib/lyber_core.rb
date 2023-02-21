# frozen_string_literal: true

require 'benchmark'
require 'socket'
require 'active_support'
require 'active_support/core_ext/object/blank' # String#blank?
require 'active_support/core_ext/module/delegation'
require 'sidekiq'
require 'honeybadger'
require 'dor/workflow/client'
require 'dor/services/client'
require 'druid-tools'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/lyber-core.rb")
loader.setup

# Elon Musk: "Robots will be able to do everything better than us"
module LyberCore
end
