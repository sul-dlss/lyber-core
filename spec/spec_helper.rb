$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib', 'dor'))

Dir[File.join(File.dirname(__FILE__), '..', 'lib', 'dor', '*.rb')].each do |file| 
  require File.basename(file, File.extname(file))
end

Dir[File.join(File.dirname(__FILE__), '..', 'lib', '*.rb')].each do |file| 
  require File.basename(file, File.extname(file))
end

require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

module Kernel
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



Rails = Object.new unless(class_exists? 'Rails')