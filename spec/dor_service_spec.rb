require File.dirname(__FILE__) + '/spec_helper'
# require 'benchmark'
require 'rubygems'
require 'nokogiri'
require 'net/http'
require 'uri'
require 'fakeweb'

describe DorService do
  it "#get_workflow_xml should throw an exception saying the method is depricated" do
    
    lambda{ DorService.get_workflow_xml('somedruid', 'someworkflow')}.should raise_error(Exception, "This method is deprecated.  Please use Dor::WorkflowService#get_workflow_xml")
  end
  
  context "DorService.encodeParams" do
    
    it "accepts a hash of arrays" do
      my_hash = {'param1' => ['val1', 'val2'], 'param2' => ['val3']}
      DorService.encodeParams(my_hash).should eql("param1=val1&param1=val2&param2=val3")
    end

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
  
  context "DorService.get_druid_by_id" do
    
    before :all do
      require File.expand_path(File.dirname(__FILE__) + "/fixtures/config/environments/test.rb")  
    end
    
    barcode = "36105014905793"
    fake_url = "http://dor-dev.stanford.edu/dor/query_by_id?id=#{barcode}"
    
    # This is more of an integration test -- it actually tests the real 
    # query_by_id webservice
    it "takes a bar code and looks up its druid" do
      DorService.get_druid_by_id(barcode).should eql("druid:tc627wc3480")
    end
    
    it "returns nil if it doesn't find a druid (any 4xx error)" do
      FakeWeb.register_uri(:get, fake_url, 
        :body => "",
        :status => ["404", "Not Found"])
      DorService.get_druid_by_id(barcode).should eql(nil)                                         
    end
    
    it "raises an error if it encounters a server error (500 code)" do
      FakeWeb.register_uri(:get, fake_url, 
        :body => "",
        :status => ["500", "Error encountered"])
      lambda{ DorService.get_druid_by_id(barcode) }.should raise_exception(/Encountered 500 error/)   
    end
    
    it "raises an error if it encounters anything unexpected (like a 3xx code)" do
      FakeWeb.register_uri(:get, fake_url, 
        :body => "",
        :status => ["301", "Moved"])
      lambda{ DorService.get_druid_by_id(barcode) }.should raise_exception(/Encountered unknown error/)   
    end
    
  end
  
  context "DorService.update_workflow_error_status" do
    repository = "dor"
    druid = "druid:pz901bm7518"
    workflow = "googleScannedBookWF"
    process = "process-content"
    
    it "cleans up any error codes that are passed" do

      error_msg = '500 "Internal Server Error"'
      error_txt = nil
      message = DorService.construct_error_update_request(process, error_msg, error_txt)
      lambda { doc = Nokogiri::XML(message) do |config|
        config.strict       
      end }.should_not raise_error
    end
    
  end
  
end