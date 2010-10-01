require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'

describe LyberCore::Robots::Workflow do
  
  context "initial state" do
    
    wf_name = "foo"
    wf_step = "bar"
    collection = "baz"
    
    it "throws an error if you instantiate it without ROBOT_ROOT" do
      lambda {LyberCore::Robots::Workflow.new(wf_name, collection)}.should raise_error(/ROBOT_ROOT/)
    end
    
    it "can be initialized as long as you set ROBOT_ROOT first" do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..")      
      wf = LyberCore::Robots::Workflow.new(wf_name, collection)
      wf.should be_instance_of(LyberCore::Robots::Workflow)
    end
    
  end
  
end