require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'

describe LyberCore::Robots::Workflow do
  
  context "environment loading" do
    
    wf_name = "sdrIngestWF"
    wf_step = "complete-deposit"
    collection = "baz"
    
    it "throws an error if you instantiate it without ROBOT_ROOT" do
      Object.send(:remove_const, :ROBOT_ROOT) if defined? ROBOT_ROOT
      lambda {LyberCore::Robots::Workflow.new(wf_name, collection)}.should raise_error(/ROBOT_ROOT/)
    end
  end
  
  context "wrong ROBOT_ROOT" do
    wf_name = "sdrIngestWF"
    wf_step = "complete-deposit"
    collection = "baz"
    incorrect_robot_root = File.expand_path(File.dirname(__FILE__) + "/../../fake/")
    
    it "raises an error if it can't find a workflow config" do
      Object.send(:remove_const, :ROBOT_ROOT) if defined? ROBOT_ROOT
      ROBOT_ROOT = incorrect_robot_root    
      lambda {LyberCore::Robots::Workflow.new(wf_name)}.should raise_error(/Workflow config not found/)      
    end
  end
  
  context "initial state" do
    
    wf_name = "sdrIngestWF"
    wf_step = "complete-deposit"
    collection = "baz"
    correct_robot_root = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")
      
    before :all do

      logfile = "/tmp/workflow_spec.log"
      logger = Logger.new(logfile)
      logger.level = 0
      
      Object.send(:remove_const, :ROBOT_ROOT) if defined? ROBOT_ROOT
      ROBOT_ROOT = correct_robot_root 

      @wf = LyberCore::Robots::Workflow.new(wf_name, {:logger => logger, :collection_name => collection})
    end
    
    it "can be initialized as long as you set ROBOT_ROOT first" do
      @wf.should be_instance_of(LyberCore::Robots::Workflow)
    end
    
    it "knows which repository to use" do
      @wf.repository.should eql("sdr")
    end
    
    it "creates a WorkQueue object" do
      wq = @wf.queue(wf_step)
      wq.should be_instance_of(LyberCore::Robots::WorkQueue)
    end
    
    it "has a workflow process file" do
      expected = File.expand_path(ROBOT_ROOT + "/config/workflows/" + wf_name + "/" + wf_name + ".xml")
      @wf.workflow_process_xml_filename.should eql(expected)
    end
    
    it "has an alias method of workflow_id that returns workflow_name" do
      @wf.workflow_id.should eql(wf_name)
      @wf.workflow_name.should eql(wf_name)
    end
    
    it "inherits a logger from robot" do
      puts @wf.logger.inspect
      @wf.logger.level.should eql(0)
      @wf.logger.debug("This is a debug statement")
    end
    
  end
  
end