require File.dirname(__FILE__) + '/spec_helper'

describe DorService do
  it "#get_workflow_xml should throw an exception saying the method is depricated" do
    
    lambda{ DorService.get_workflow_xml('somedruid', 'someworkflow')}.should raise_error(Exception, "This method is deprecated.  Please use Dor::WorkflowService#get_workflow_xml")
  end
end