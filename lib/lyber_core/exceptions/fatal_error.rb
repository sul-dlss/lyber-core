require File.join(File.dirname(__FILE__), 'chained_error')

# A ServiceError is used to wrap timeouts, HTTP exceptions, etc
# And create a new exception that is usually treated as a fatal error
module LyberCore
  module Exceptions
    class FatalError < LyberCore::Exceptions::ChainedError
    end
  end
end