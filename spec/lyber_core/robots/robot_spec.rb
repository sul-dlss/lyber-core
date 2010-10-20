require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'
require File.expand_path(File.dirname(__FILE__) + "/test_robot.rb")  

describe LyberCore::Robots::Robot do
    
  describe "environment loading" do
      
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    collection = "baz"
    valid_logfile = "/tmp/fakelog.log"
  
    # it "raises an exception if WORKFLOW_URI is not defined" do
    #   pending "This test passes when run on its own, but undefining WORKFLOW_URI seems to break the other tests"
    #   Object.send(:remove_const, :WORKFLOW_URI) if defined? WORKFLOW_URI
    #   lambda { robot = TestRobot.new("sdrIngestWF", "populate-metadata", :logfile => valid_logfile) }.should raise_exception(/WORKFLOW_URI is not set/)        
    # end
      
  end
  
  
  
  context "initial state" do
    
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
    valid_logfile = "/tmp/fakelog.log"
    invalid_logfile = "/zzxx/fakelog.log"
 
    before :each do
      LyberCore::Log.restore_defaults
    end
  
    it "can set the location of the log file when it is created" do
      robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile)
      LyberCore::Log.logfile.should eql(valid_logfile)
    end
  
    it "can set the log level when it is created" do
      robot = TestRobot.new(wf_name, wf_step, 
        :loglevel => Logger::DEBUG, 
        :logfile => valid_logfile)
      LyberCore::Log.level.should eql(Logger::DEBUG)       
    end
      
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
            
  context "command line options" do
    
    workflow_name = "googleScannedBookWF"
    
    it "can accept a single druid for processing" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--druid=sdrtwo:blah"
      robot = TestRobot.new(workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.get_druid_list[0].should eql("sdrtwo:blah")
    end
    
    it "can accept a file of druids for processing" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--file=fakefile"
      robot = TestRobot.new(workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.options.file.should eql("fakefile")
    end
    
    # Cucumber passes "--format pretty" as an argument, which can make the robots fail unless
    # we check for it. 
    it "shouldn't fail when run by cucumber" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--format pretty"
      lambda { TestRobot.new(workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain') }.should_not raise_exception()
    end
    
    it "can override the default logfile via the commandline" do
      pending
    end
    
    it "can override the default log level via the commandline" do
      pending
    end
    
    it "can accept both a file of druids for processing and a logfile on a single command line" do
      pending
    end
    
  end
  
  
  
  context "other" do
      
      workflow_name = "googleScannedBookWF"

      it "should process a batch of druids from the Workflow" do   
        
        require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    
        robot = TestRobot.new(workflow_name, "descriptive-metadata", :collection_name => 'publicDomain')
        # puts robot.workflow.inspect
        # puts robot.workflow.queue('descriptive-metadata')
    
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
        robot = TestRobot.new(workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
    
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