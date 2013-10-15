require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + "/test_robot.rb")
require 'fakeweb'


describe LyberCore::Robots::WorkQueue do
  
  workflow_name = "googleScannedBookWF"
    
  context "initial state" do
    ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures") unless defined? ROBOT_ROOT
    require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    workflow_step = "descriptive-metadata"
  
    it "instantiates a WorkQueue" do
      robot = TestRobot.new(workflow_name, workflow_step, {:collection_name => 'publicDomain', :loglevel => 0})
      wq = LyberCore::Robots::WorkQueue.new(robot.workflow, workflow_step) 
    end
   
   it "can tell you where its config file is" do
     robot = TestRobot.new(workflow_name, workflow_step, {:collection_name => 'publicDomain'})
     wq = LyberCore::Robots::WorkQueue.new(robot.workflow, workflow_step)
   end
   
   it "loads a config file" do
     workflow = double("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     wq = LyberCore::Robots::WorkQueue.new(workflow, "descriptive-metadata")
     wq.config_file.should eql(workflow_config_dir + "/process-config.yaml")
   end
   
   it "raises a helpful error if it can't find the config file" do
     workflow = double("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixddddtures/config/workflowz/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     lambda { LyberCore::Robots::WorkQueue.new(workflow, "descriptive-metadata") }.should raise_exception(/Can't open process-config file/)        
   end
   
   it "knows how many items to process in a batch" do
     workflow = double("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     wq = LyberCore::Robots::WorkQueue.new(workflow, "descriptive-metadata")
     wq.batch_limit.should eql(5)
   end
   
   it "handles steps with two prequisites" do
      workflow = double("workflow")
      workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
      workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
      wq = LyberCore::Robots::WorkQueue.new(workflow, "cleanup")
      wq.prerequisite.should =~ ["sdr-ingest-deposit", "shelve"]
    end
   
   it "handles fully qualified workflow step names in the config file" do
     workflow = double("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     wq = LyberCore::Robots::WorkQueue.new(workflow, "cleanup-qualified")
     wq.prerequisite.should =~ ["sdr:sdrIngestWF:complete-deposit", "dor:googleScannedBookWF:shelve"]
   end
  
  end
  
  context "enqueue_workstep_waiting" do
    
    context "normal processing" do
      before(:each) do
        @workflow = double("workflow")
        @workflow.stub(:repository).and_return("dor")
        @workflow.stub(:workflow_id).and_return("googleScannedBookWF")
        @workflow.stub(:completed).and_return("register-object")
        @workflow.stub(:waiting).and_return("descriptive-metadata")
        workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
        @workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
      end

      it "only grabs as many druids as it needs for a batch" do
        queuefile = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/queue.xml")
        (File.file? queuefile).should eql(true)
        queue = IO.read(queuefile)
        FakeWeb.register_uri(:get, %r|lyberservices-dev\.stanford\.edu/|,
          :body => queue)
        wq = LyberCore::Robots::WorkQueue.new(@workflow, @workflow.waiting)
        wq.enqueue_workstep_waiting
        wq.druids.length.should eql(wq.batch_limit)
        FakeWeb.clean_registry
      end

      it "enqueue_workstep_waiting catches and raises an EmptyQueue exception" do
        FakeWeb.register_uri(:get, %r|lyberservices-dev\.stanford\.edu/|,
          :body => '<objects count="0" />')
        wq = LyberCore::Robots::WorkQueue.new(@workflow, @workflow.waiting)
        lambda { wq.enqueue_workstep_waiting }.should raise_exception(LyberCore::Exceptions::EmptyQueue)
      end
    end
    
    context "fully qualified prequisites" do
      before(:each) do
        ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures") unless defined? ROBOT_ROOT
        require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
        
        @workflow = double("workflow")
        workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
        @workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
        @workflow.stub(:repository).and_return("dor")
        @workflow.stub(:workflow_id).and_return("googleScannedBookWF")     
      end
      
      it "calls the correct DorService to grab druids with fully qualified workflow names" do
        @wq = LyberCore::Robots::WorkQueue.new(@workflow, "cleanup-qualified")
        Dor::WorkflowService.stub(:get_objects_for_workstep).and_return(["druid:123456a","druid:654321b","druid:654321c","druid:567890d"])
        Dor::WorkflowService.should_receive(:get_objects_for_workstep).once.with(@wq.prerequisite, 'cleanup-qualified', 'dor', workflow_name)
        @wq.enqueue_workstep_waiting
      end
      
      it "calls the correct DorService to grab druids with fully qualified workflow names, only 1 completed step" do
        @wq = LyberCore::Robots::WorkQueue.new(@workflow, "shelve-qualified")
        Dor::WorkflowService.stub(:get_objects_for_workstep).and_return(["druid:123456"])
        Dor::WorkflowService.should_receive(:get_objects_for_workstep).with('dor:googleScannedBookWF:process-content', 
          'shelve-qualified', 'dor', workflow_name)
        @wq.enqueue_workstep_waiting
      end
    end
    
    
  end
  
end