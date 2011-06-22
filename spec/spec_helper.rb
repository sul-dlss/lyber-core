$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spec'
require 'spec/autorun'

require 'rubygems'
require 'lyber_core'
require 'lyber_core/utils'
require 'ruby-debug'

Spec::Runner.configure do |config|
  
end

module Kernel
  def require_one(*args)
    args.each do |mod|
      begin
        return require(mod)
      rescue LoadError
      end
    end
    raise LoadError, "could not load any of the following -- #{args.join(', ')}"
  end
  
  # Suppresses warnings within a given block.
  def with_warnings_suppressed
    saved_verbosity = $-v
    $-v = nil
    yield
  ensure
    $-v = saved_verbosity
  end
end

def class_exists?(class_name)
  klass = Module.const_get(class_name)
  return klass.is_a?(Class)
rescue NameError
  return false
end


Rails = Object.new unless defined? Rails
# Rails = Object.new unless(class_exists? 'Rails')