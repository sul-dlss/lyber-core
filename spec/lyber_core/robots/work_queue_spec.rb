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
      robot = TestRobot.new(workflow_name, workflow_step, {:collection_name => 'publicDomain'})
      wq = LyberCore::Robots::WorkQueue.new(robot.workflow, workflow_step) 
    end
   
   it "can tell you where its config file is" do
     robot = TestRobot.new(workflow_name, workflow_step, {:collection_name => 'publicDomain'})
     wq = LyberCore::Robots::WorkQueue.new(robot.workflow, workflow_step)
     puts wq.config_file
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
  
  end
  
end