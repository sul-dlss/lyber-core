$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'bundler/setup'
require 'rspec'
require 'dor-services'
require 'lyber_core'
require 'pry'

RSpec.configure do |config|

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


Rails = Object.new unless defined? Rails

# capture stdout so that we can assert expectations on it
require 'stringio'

def capture_stdout(&blk)
  old = $stdout
  $stdout = fake = StringIO.new
  blk.call
  fake.string
ensure
  $stdout = old
end