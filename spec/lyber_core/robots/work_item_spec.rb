require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'


describe LyberCore::Robots::WorkItem do

  before(:all) do 
    @work_queue = mock("WorkQueue", :null_object => true)
  end #before(:all)

  before(:each) do
    @work_item = LyberCore::Robots::WorkItem.new(@work_queue)
  end
  
  describe "#set_status" do

    it "should set a named status when told to" do
      pending # The @work_queue mock needs to be fleshed out more for this to work
#      @work_item.druid = "changeme:boosh"
#      DorService.should_receive(:update_workflow_status).with(anything(), "changeme:boosh", anything(), anything(), 'testing', anything()).and_return(true)
#      @work_item.set_status('testing')
    end
  end #set_status
  

  describe "#set_success" do

    it "should set the success when told to" do    
      pending # The @work_queue mock needs to be fleshed out more for this to work
#      @work_item.druid = "changeme:boosh"
#      DorService.should_receive(:update_workflow_status).with(anything(), "changeme:boosh", anything(), anything(), 'completed', anything()).and_return(true)
#      @work_item.set_success
    end 

  end #set_success

  describe "#set_error" do

    before(:each) do
      @work_queue.should_receive(:error_count).and_return(0)
      @work_queue.should_receive(:error_count=)
      @work_queue.should_receive(:workflow_step).and_return("fake-workflow-step")
      @workflow = mock("workflow")
      @workflow.should_receive(:repository).and_return("dor")
      @workflow.should_receive(:workflow_id).and_return("googleScannedBookWF")
      @work_queue.stub(:workflow).and_return(@workflow)
      Dor::WorkflowService.should_receive(:update_workflow_error_status).and_return(true)
      @work_item.druid = "changeme:boosh"
    end

    it "sets an error with a standard exception" do
      e = Exception.new("The sky is falling!")
      @work_item.set_error(e)
    end

    it "sets an error with a Errno::EACCES error" do
      e = Errno::EACCES.new
      @work_item.set_error(e)    
    end

  end
    
end #LyberCore::WorkItem