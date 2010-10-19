require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'
require File.expand_path(File.dirname(__FILE__) + "/test_robot.rb")  


describe LyberCore::Robots::WorkQueue do
  
  workflow_name = "googleScannedBookWF"
    
  context "initial state" do
    ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures")
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
     workflow = stub("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     wq = LyberCore::Robots::WorkQueue.new(workflow, "descriptive-metadata")
     wq.config_file.should eql(workflow_config_dir + "/process-config.yaml")
   end
   
   it "raises a helpful error if it can't find the config file" do
     workflow = stub("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixddddtures/config/workflowz/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     lambda { LyberCore::Robots::WorkQueue.new(workflow, "descriptive-metadata") }.should raise_exception(/Can't open process-config file/)        
   end
   
   it "knows how many items to process in a batch" do
     workflow = stub("workflow")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     wq = LyberCore::Robots::WorkQueue.new(workflow, "descriptive-metadata")
     wq.batch_limit.should eql(5)
   end
   
   it "only grabs as many druids as it needs for a batch" do
     workflow = stub("workflow")
     workflow.stub(:repository).and_return("dor")
     workflow.stub(:workflow_id).and_return("googleScannedBookWF")
     workflow.stub(:completed).and_return("register-object")
     workflow.stub(:waiting).and_return("descriptive-metadata")
     workflow_config_dir = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/workflows/" + workflow_name)
     workflow.stub(:workflow_config_dir).and_return(workflow_config_dir)
     queue = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/queue.xml")
     (File.file? queue).should eql(true)
     DorService.stub(:all).and_return(queue)
     wq = LyberCore::Robots::WorkQueue.new(workflow, workflow.waiting)
     wq.enqueue_workstep_waiting
     wq.druids.length.should eql(wq.batch_limit)
   end
  
  end
  
end