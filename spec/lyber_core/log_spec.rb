require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'lyber_core'


describe LyberCore::Log do
  
  describe "initial state" do
    
    before :each do
      LyberCore::Log.restore_defaults
    end
    
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    collection = "baz"
    valid_logfile = "/tmp/fakelog.log"
    invalid_logfile = "/zzxx/fakelog.log"
    with_warnings_suppressed do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../fixtures")
    end

    it "has a default value for logfile" do
      LyberCore::Log.logfile.should eql(LyberCore::Log::DEFAULT_LOGFILE)
    end
    
    it "can set the location of the logfile" do
      LyberCore::Log.set_logfile(valid_logfile)
      LyberCore::Log.logfile.should eql(valid_logfile)
    end

    it "throws an error and does not change location of logfile if passed an invalid location for a logfile" do
      lambda { LyberCore::Log.set_logfile(invalid_logfile)}.should raise_exception(/Couldn't initialize logfile/)         
      LyberCore::Log.logfile.should eql(LyberCore::Log::DEFAULT_LOGFILE)
    end
    
    it "can report its log level" do
      LyberCore::Log.should respond_to(:level)
    end

    it "starts in info reporting mode (log level 1)" do
      LyberCore::Log.level.should eql(Logger::INFO)       
    end
    
    it "can be put into debug mode (log level 0)" do  
      LyberCore::Log.set_level(0)
      LyberCore::Log.level.should eql(Logger::DEBUG)       
    end
    
    it "goes into debug mode if it receives an invalid option for loglevel" do
      LyberCore::Log.set_level("foo")
      LyberCore::Log.level.should eql(Logger::DEBUG)
    end
    
    it "keeps the same logging level when switching to a different file" do
      LyberCore::Log.set_level(Logger::DEBUG)
      LyberCore::Log.set_logfile(LyberCore::Log::DEFAULT_LOGFILE)
      LyberCore::Log.set_logfile(valid_logfile)
      LyberCore::Log.level.should eql(Logger::DEBUG)       
    end
    
    
    it "can write to the log file" do
      onetimefile = "/tmp/onetimefile"
      File.delete onetimefile if File.exists? onetimefile
      LyberCore::Log.set_logfile(onetimefile)
      LyberCore::Log.logfile.should eql(onetimefile)
      LyberCore::Log.set_level(3)
      (File.file? onetimefile).should eql(true)
      LyberCore::Log.error("This is an error")
      LyberCore::Log.debug("Debug info 1")
      LyberCore::Log.info("This is some info")
      LyberCore::Log.error("This is another error")
      contents = open(onetimefile) { |f| f.read }
      contents.should match(/This is an error/)
      contents.should match(/This is another error/)
      contents.should_not match(/This is some info/)
      contents.should_not match(/Debug info 1/)
      File.delete onetimefile
      (File.exists? onetimefile).should eql(false)
    end
    
    it "prints debugging statements when in debugging mode" do
      onetimefile = "/tmp/debugfile"
      File.delete onetimefile if File.exists? onetimefile
      LyberCore::Log.set_logfile(onetimefile)
      LyberCore::Log.logfile.should eql(onetimefile)
      LyberCore::Log.set_level(0)      
      (File.file? onetimefile).should eql(true)
      LyberCore::Log.debug("Debug info 1")
      LyberCore::Log.fatal("Oh nooooo!")
      LyberCore::Log.debug("More debug stuff")
      LyberCore::Log.info("And here is some info")
      contents = open(onetimefile) { |f| f.read }
      contents.should match(/Debug info 1/)
      contents.should match(/Oh nooooo!/)
      File.delete onetimefile
      (File.exists? onetimefile).should eql(false)
    end
    
    it "can restore its default state" do
      LyberCore::Log.restore_defaults
      LyberCore::Log.level.should eql(LyberCore::Log::DEFAULT_LOG_LEVEL)       
      LyberCore::Log.logfile.should eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it "can format an error message from an exception" do
      re = RuntimeError.new("runtime message")
      re.set_backtrace(caller)
      log_msg = LyberCore::Log.exception_message(re)
      log_msg.should eql "#{re.inspect}\n" << re.backtrace.join("\n")
    end

    it "will replace newlines with semicolons when logging an exception with a multiline message" do
      msg = "runtime\nmessage"
      re = RuntimeError.new(msg)
      re.set_backtrace(caller)
      log_msg = LyberCore::Log.exception_message(re)
      log_msg.should eql "#<RuntimeError: runtime; message>\n" <<  re.backtrace.join("\n")
    end

    it "can log information from any exception object" do
      re = RuntimeError.new("runtime message")
      re.set_backtrace(caller)
      log_msg = LyberCore::Log.exception_message(re)
      LyberCore::Log.should_receive(:error).with(log_msg)
      LyberCore::Log.exception(re)
    end


    it "can log information from an FatalError exception object" do
      re = RuntimeError.new("runtime message")
      re.set_backtrace(caller)
      se = LyberCore::Exceptions::ServiceError.new("service message", re)
      log_msg = LyberCore::Log.exception_message(se)
      LyberCore::Log.should_receive(:fatal).with(log_msg)
      LyberCore::Log.exception(se)
    end


  end
  

  
end