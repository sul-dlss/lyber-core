require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'

describe LyberCore::Robots::Workflow do
  
  context "initial state" do
    
    wf_name = "sdrIngestWF"
    wf_step = "complete-deposit"
    collection = "baz"
    
    it "throws an error if you instantiate it without ROBOT_ROOT" do
      lambda {LyberCore::Robots::Workflow.new(wf_name, collection)}.should raise_error(/ROBOT_ROOT/)
    end
    
    it "can be initialized as long as you set ROBOT_ROOT first" do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")      
      wf = LyberCore::Robots::Workflow.new(wf_name, collection)
      wf.should be_instance_of(LyberCore::Robots::Workflow)
    end
    
    it "raises an error if it can't find a workflow config" do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../fake/")      
      lambda {LyberCore::Robots::Workflow.new(wf_name, collection)}.should raise_error(/Workflow config not found/)      
    end
    
    it "knows which repository to use" do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")      
      wf = LyberCore::Robots::Workflow.new(wf_name, collection)
      wf.repository.should eql("sdr")
    end
    
    it "creates a WorkQueue object" do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")      
      wf = LyberCore::Robots::Workflow.new(wf_name, collection)
      wq = wf.queue(wf_step)
      wq.should be_instance_of(LyberCore::Robots::WorkQueue)
    end
    
  end
  
end