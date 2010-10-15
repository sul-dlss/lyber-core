require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'lyber_core'
require 'lyber_core/log'
require File.expand_path(File.dirname(__FILE__) + "/robots/test_robot.rb")  

describe LyberCore::Log do
  
  describe "initial state" do
    
    wf_name = "sdrIngestWF"
     wf_step = "populate-metadata"
     collection = "baz"
     default_logfile = "/tmp/lybercore_log.log"
     valid_logfile = "/tmp/fakelog.log"
     invalid_logfile = "/zzxx/fakelog.log"
     ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures")
     WORKFLOW_URI = 'http://lyberservices-dev.stanford.edu/workflow'
     
    it "has a default value for logfile" do
      LyberCore::Log.logfile.should eql(default_logfile)
    end
    
    it "can set the location of the logfile and then set it back again" do
      LyberCore::Log.set_logfile(default_logfile)
      LyberCore::Log.logfile.should eql(default_logfile)
      LyberCore::Log.set_logfile(valid_logfile)
      LyberCore::Log.logfile.should eql(valid_logfile)
      LyberCore::Log.set_logfile(default_logfile)
      LyberCore::Log.logfile.should eql(default_logfile)
    end

    it "throws an error and does not change location of logfile if passed an invalid location for a logfile" do
      LyberCore::Log.set_logfile(default_logfile)
      LyberCore::Log.logfile.should eql(default_logfile)
      lambda { LyberCore::Log.set_logfile(invalid_logfile)}.should raise_exception(/Couldn't initialize logfile/)         
      LyberCore::Log.logfile.should eql(default_logfile)
    end
    
    it "can report its log level" do
      LyberCore::Log.should respond_to(:level)
    end

    it "starts in error reporting mode (log level 3)" do
      LyberCore::Log.level.should eql(Logger::ERROR)       
    end
    
    it "can be put into debug mode (log level 0)" do
      LyberCore::Log.set_level(3)
      LyberCore::Log.level.should eql(Logger::ERROR)       
      LyberCore::Log.set_level(0)
      LyberCore::Log.level.should eql(Logger::DEBUG)       
    end
    
    it "goes into debug mode if it receives an invalid option for loglevel" do
      LyberCore::Log.set_level(3)
      LyberCore::Log.level.should eql(Logger::ERROR)       
      LyberCore::Log.set_level("foo")
      LyberCore::Log.level.should eql(Logger::DEBUG)
    end
    
    # it "keeps the same logging level when switching to a different file" do
    #   LyberCore::Log.set_level(0)
    #   LyberCore::Log.set_logfile(default_logfile)
    #   LyberCore::Log.set_logfile(valid_logfile)
    #   LyberCore::Log.level.should eql(Logger::DEBUG)       
    # end
          # 
          # it "can be instantiated in debug mode (log level 0)" do
          #   robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile, :loglevel => 0)
          #   robot.log_level.should eql(Logger::DEBUG) 
          # end
          # 

          # 
          # it "can write to the log file" do
          #   onetimefile = "/tmp/onetimefile"
          #   File.delete onetimefile if File.exists? onetimefile
          #   robot = TestRobot.new(wf_name, wf_step, :logfile => onetimefile)
          #   (File.file? onetimefile).should eql(true)
          #   robot.logger.error("This is an error")
          #   robot.logger.debug("Debug info 1")
          #   robot.logger.info("This is some info")
          #   robot.logger.error("This is another error")
          #   contents = open(onetimefile) { |f| f.read }
          #   contents.should match(/This is an error/)
          #   contents.should match(/This is another error/)
          #   contents.should_not match(/This is some info/)
          #   contents.should_not match(/Debug info 1/)
          #   File.delete onetimefile
          #   (File.exists? onetimefile).should eql(false)
          #   
          # end
          # 
          # it "prints debugging statements when in debugging mode" do
          #   onetimefile = "/tmp/debugfile"
          #   File.delete onetimefile if File.exists? onetimefile
          #   robot = TestRobot.new(wf_name, wf_step, :logfile => onetimefile, :loglevel => 0)
          #   (File.file? onetimefile).should eql(true)
          #   robot.logger.debug("Debug info 1")
          #   robot.logger.fatal("Oh nooooo!")
          #   robot.logger.debug("More debug stuff")
          #   robot.logger.info("And here is some info")
          #   contents = open(onetimefile) { |f| f.read }
          #   contents.should match(/Debug info 1/)
          #   contents.should match(/Oh nooooo!/)
          #   File.delete onetimefile
          #   (File.exists? onetimefile).should eql(false)
          # end
    
  end
  

  
end