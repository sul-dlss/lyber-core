require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core/exceptions/chained_error'
require 'lyber_core/exceptions/service_error'
require 'lyber_core/exceptions/item_error'

describe LyberCore::Exceptions::ChainedError do

  it "should initialize without a causal exception" do
    msg = "my message"
    ce  = LyberCore::Exceptions::ChainedError.new(msg)
    ce.message.should eql msg
    ce.backtrace.should eql nil
  end

  it "should initialize without a causal exception and get a backtrace when raised" do
    msg = "my message"
    ce  = LyberCore::Exceptions::ChainedError.new(msg)
    begin
      raise ce
    rescue LyberCore::Exceptions::ChainedError => e
      e.message.should eql msg
      e.backtrace.length.should be > 0
    end
  end

  it "should preserve information from a causal exception" do
    ie_msg = "interrupt message"
    se_msg = "service message"
    begin
      begin
        raise Interrupt, ie_msg
      rescue Interrupt => ie
        raise LyberCore::Exceptions::ChainedError.new(se_msg, ie)
      end
    rescue LyberCore::Exceptions::ChainedError => ce
      # se.message == "service message; caused by #<Interrupt: interrupt message>"
      ce.message.should eql "#{se_msg}; caused by #{ie.inspect}"
      ce.backtrace.should eql ie.backtrace
    end
  end

  describe LyberCore::Exceptions::ServiceError do

    it "should inherit from ChainedError" do
      msg = "my message"
      se  = LyberCore::Exceptions::ServiceError.new(msg)
      se.is_a?(LyberCore::Exceptions::ChainedError).should be true
    end

  end


  describe LyberCore::Exceptions::ItemError do

    it "should inherit from ChainedError" do
      druid = "druid:xy123"
      msg = "my message"
      ie  = LyberCore::Exceptions::ItemError.new(druid, msg)
      ie.is_a?(LyberCore::Exceptions::ChainedError).should be true
    end

    it "should fail to initialize unless passed a druid and message text" do
      druid = "druid:xy123"
      msg = "my message"
      lambda { LyberCore::Exceptions::ItemError.new(msg) }.should raise_error
      ie  = LyberCore::Exceptions::ItemError.new(druid,msg)
      ie.message.should eql "#{druid} - #{msg}"
      ie.backtrace.should eql nil
    end

    it "should preserve information from a causal exception" do
      re_msg = "runtime message"
      ie_msg = "item message"
      druid = "druid:xy123"
      begin
        begin
          raise RuntimeError, re_msg
        rescue RuntimeError => re
          raise LyberCore::Exceptions::ItemError.new(druid, ie_msg, re)
        end
      rescue LyberCore::Exceptions::ItemError => ie
        # ie.message == "druid:xy123 - item message; caused by #<RuntimeError: runtime message>"
        ie.message.should eql "#{druid} - #{ie_msg}; caused by #{re.inspect}"
        ie.backtrace.should eql re.backtrace
      end
    end

  end

end