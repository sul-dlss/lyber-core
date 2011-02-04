require File.join(File.dirname(__FILE__), 'chained_error')

# A ItemError is used to wrap a causal exception
# And create a new exception that usually terminates processing of the current item
# the druid parameter makes it convenient to include the object id using a std message syntax
module LyberCore
  module Exceptions
    class ItemError < LyberCore::Exceptions::ChainedError
      def initialize(druid, msg, cause=nil)
        message = "#{druid} - #{msg}"
        super(message, cause)
      end
    end
  end
end