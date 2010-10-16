require File.dirname(__FILE__) + '/spec_helper'
# require 'benchmark'

describe DorService do
  it "#get_workflow_xml should throw an exception saying the method is depricated" do
    
    lambda{ DorService.get_workflow_xml('somedruid', 'someworkflow')}.should raise_error(Exception, "This method is deprecated.  Please use Dor::WorkflowService#get_workflow_xml")
  end
  
  context "workflow" do
    
    it "transforms xml from the workflow service into a list of druids" do
      # puts Benchmark.measure {
      queue = open(File.expand_path(File.dirname(__FILE__) + "/fixtures/queue.xml"))
      array = DorService.get_druids_from_object_list(queue)
      array.should be_kind_of(Array)
      array[0].should eql("druid:hx066mp6063")
      array.length.should eql(9)
      # }
    end
  
  end
  
end