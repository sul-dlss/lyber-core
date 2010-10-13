require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'
require File.expand_path(File.dirname(__FILE__) + "/test_robot.rb")  

describe LyberCore::Robots::Robot do
    
  describe "environment loading" do
      
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    collection = "baz"
    valid_logfile = "/tmp/fakelog.log"
  
    it "raises an exception if WORKFLOW_URI is not defined" do
      pending "This test passes when run on its own, but undefining WORKFLOW_URI seems to break the other tests"
      Object.send(:remove_const, :WORKFLOW_URI) if defined? WORKFLOW_URI
      lambda { robot = TestRobot.new("sdrIngestWF", "populate-metadata", :logfile => valid_logfile) }.should raise_exception(/WORKFLOW_URI is not set/)        
    end
      
  end
  
  describe "initial state" do
    
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    collection = "baz"
    
    before :each do
      require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    end
  
    it "has accessor methods" do
      robot = TestRobot.new(wf_name, wf_step, :collection_name => collection)
      robot.workflow_name.should eql(wf_name)
      robot.workflow_step.should eql(wf_step)
      robot.collection_name.should eql(collection)
    end
  
    it "has default values for its options" do
      robot = TestRobot.new(wf_name, wf_step, :collection_name => collection)
      robot.options.verbose.should eql(false)
      robot.options.quiet.should eql(false)
    end
  
    # it "has a workflow after it has started" do
    #   ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..")      
    #   robot = TestRobot.new("googleScannedBookWF","register-object", :collection_name => collection)
    #   robot.start
    #   puts robot.workflow
    # end
  
  end

  context "logging" do
    
    require 'dor_service'
    require 'dlss_service'
    require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    collection = "baz"
    valid_logfile = "/tmp/fakelog.log"
    invalid_logfile = "/zzxx/fakelog.log"
    ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures")
    WORKFLOW_URI = 'http://lyberservices-dev.stanford.edu/workflow'
    
      it "has a logfile" do
        robot = TestRobot.new(wf_name, wf_step, :collection_name => collection)
        robot.logfile.should eql("/tmp/logfile.log")
      end
      
      it "can set the location of the logfile" do
        robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile)
        robot.logfile.should eql(valid_logfile)
      end
      
      it "throws an error if passed an invalid location for a logfile" do
        lambda { robot = TestRobot.new(wf_name, wf_step, :logfile => invalid_logfile) }.should raise_exception(/Couldn't initialize logfile/)        
      end

      it "starts in error reporting mode (log level 3)" do
        robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile)
        robot.log_level.should eql(Logger::ERROR) 
      end
      
      it "can be put into debug mode (log level 0)" do
        robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile)
        robot.set_log_level(Logger::DEBUG)
        robot.log_level.should eql(Logger::DEBUG) 
      end
      
      it "can be instantiated in debug mode (log level 0)" do
        robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile, :loglevel => 0)
        robot.log_level.should eql(Logger::DEBUG) 
      end
      
      it "goes into debug mode if it receives an invalid option for loglevel" do
        robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile, :loglevel => "foo")
        robot.log_level.should eql(Logger::DEBUG) 
      end
      
      it "can write to the log file" do
        onetimefile = "/tmp/onetimefile"
        (File.exists? onetimefile).should eql(false)
        robot = TestRobot.new(wf_name, wf_step, :logfile => onetimefile)
        (File.file? onetimefile).should eql(true)
        robot.logger.error("This is an error")
        robot.logger.debug("Debug info 1")
        robot.logger.info("This is some info")
        robot.logger.error("This is another error")
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
        (File.exists? onetimefile).should eql(false)
        robot = TestRobot.new(wf_name, wf_step, :logfile => onetimefile, :loglevel => 0)
        (File.file? onetimefile).should eql(true)
        robot.logger.debug("Debug info 1")
        robot.logger.fatal("Oh nooooo!")
        robot.logger.debug("More debug stuff")
        robot.logger.info("And here is some info")
        contents = open(onetimefile) { |f| f.read }
        contents.should match(/Debug info 1/)
        contents.should match(/Oh nooooo!/)
        File.delete onetimefile
        (File.exists? onetimefile).should eql(false)
      end
      
      # it "prints debugging statements when in debugging mode" do  
      #   robot = TestRobot.new("sdrIngestWF", "populate-metadata", :logfile => valid_logfile)
      #   # puts robot.inspect
      #   # robot.start
      # end
    
  end
    
  context "workflow" do
    
    before :each do
      require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    end
    
    require 'dor_service'      
    ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures") unless defined? ROBOT_ROOT
    workflow_logfile = "/tmp/workflow_testing.log"
    
    it "can inspect its workflow object" do
      robot = TestRobot.new("sdrIngestWF", "populate-metadata", :logfile => workflow_logfile)
      robot.workflow.repository.should eql("sdr")
    end
  
  end
  
  context "other" do
  
    it "can accept a single druid for processing" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--druid=sdrtwo:blah"
      robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.get_druid_list[0].should eql("sdrtwo:blah")
    end
  
    it "can accept a file of druids for processing" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--file=fakefile"
      robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.options.file.should eql("fakefile")
    end
    
    # Cucumber passes "--format pretty" as an argument, which can make the robots fail unless
    # we check for it. 
    it "shouldn't fail when run by cucumber" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--format pretty"
      lambda { TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain') }.should_not raise_exception()
    end  
  
    it "should process a batch of druids from the Workflow" do   
      
      require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  

      robot = TestRobot.new("googleScannedBook", "descriptive-metadata", :collection_name => 'publicDomain')
      puts robot.workflow.inspect
      puts robot.workflow.queue('descriptive-metadata')

      # mock_workflow = mock('workflow')
      # mock_queue = mock('queue')
      # robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
      # LyberCore::Robots::Workflow.should_receive(:new).and_return(mock_workflow)
      # mock_workflow.should_receive(:queue).with('descriptive-metadata').and_return(mock_queue)
      # ARGV.stub!(:size).and_return(0)
      # mock_queue.should_receive(:enqueue_workstep_waiting)
      # robot.should_receive(:process_queue).and_return(nil)
      # robot.start
    end

    it "should process queue of objects" do

      mock_queue = mock('queue')
      mock_item = mock('item')
      mock_mdutils = mock('mdutils')
      mock_dorservice = mock('dorservice')
      robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')

      #Return the mock item the first time, return nil the second time to stop the while loop
      mock_queue.should_receive(:next_item).and_return(mock_item, nil)
      mock_queue.should_receive(:print_stats)

      #inside the while loop
      mock_item.should_receive(:set_success)

      robot.should_receive(:process_item)

      robot.process_queue(mock_queue)

    end
  end
  
  
end