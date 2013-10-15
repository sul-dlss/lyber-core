require 'spec_helper'


describe LyberCore::Robots::WorkItem do

  before(:each) do
    @work_queue = double("WorkQueue").as_null_object
    @work_item = LyberCore::Robots::WorkItem.new(@work_queue)
    
    @mock_resource = double('RestClient::Resource')
    @mock_resource.stub(:[]).and_return(@mock_resource)
    RestClient::Resource.stub(:new).and_return(@mock_resource)
  end
  
  describe "#set_status" do

    it "should set a named status when told to" do
      @work_item.druid = "changeme:boosh"
       @mock_resource.should_receive(:put)
       @work_item.set_success
    end
  end #set_status
  

  describe "#set_success" do

    it "should set the success when told to" do    
     @work_item.druid = "changeme:boosh"
     @mock_resource.should_receive(:put)
     @work_item.set_success
    end 

  end #set_success

  describe "#set_error" do

    before(:each) do
      @work_queue.should_receive(:error_count).and_return(0)
      @work_queue.should_receive(:error_count=)
      @work_queue.should_receive(:workflow_step).and_return("fake-workflow-step")
      @workflow = double("workflow")
      @workflow.should_receive(:repository).and_return("dor")
      @workflow.should_receive(:workflow_id).and_return("googleScannedBookWF")
      @work_queue.stub(:workflow).and_return(@workflow)
      @mock_resource.should_receive(:put)
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