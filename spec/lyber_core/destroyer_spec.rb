require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + "/../fixtures/config/environments/test.rb")  
require 'fakeweb'

describe LyberCore::Destroyer do
  
  before :all do
    FakeWeb.allow_net_connect = false
    fixture_metadata = open(File.expand_path(File.dirname(__FILE__) + "/../fixtures/objects.xml")) { |f| f.read }
    FakeWeb.register_uri(:get, %r|lyberservices-dev\.stanford\.edu|, :body => fixture_metadata)
    @dfo = LyberCore::Destroyer.new("dor","googleScannedBookWF", "register-object")
  end

  after :all do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
  end

    
  context "fetching druids" do   
      
    it "accepts a repository, a workflow, and the name of the registration robot" do
      @dfo.repository.should eql("dor")
      @dfo.workflow.should eql("googleScannedBookWF")
      @dfo.registration_robot.should eql("register-object")
    end
  
    it "knows its WORKFLOW_URI" do
      WORKFLOW_URI.should eql("http://lyberservices-dev.stanford.edu/workflow")
    end

    it "can get all the druids for a workflow" do
      @dfo.druid_list.length.should eql(11)
    end
    
  end

  context "delete from fedora" do
    
    it "has a method that tells it to delete the druids" do
      @dfo.should respond_to(:delete_druids)
    end
    
  end
end