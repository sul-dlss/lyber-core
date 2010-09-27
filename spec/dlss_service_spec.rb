require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'dlss_service'
require 'benchmark'

describe DlssService do
  
  
  context "context" do
    it "transforms xml from the workflow service into a list of druids" do
      require 'open-uri'
        queue = open(File.expand_path(File.dirname(__FILE__) + "/fixtures/queue.xml"))
        array = DorService.get_druids_from_object_list(queue)
        array.should be_kind_of(Array)
        array[0].should eql("druid:hx066mp6063")
        array.length.should eql(9)
        puts array.length
    end
  end
  
  
  context "fedora" do
    
    before(:each) do
      @fedora_url = "https://fedoraAdmin:fedoraAdmin@sdr-fedora-dev.stanford.edu/fedora"
      @service = DlssService.new(@fedora_url)
    end

    it "should know its fedora url" do
      @service.fedora_url.should == @fedora_url
    end
  
    it "should be able to get a datastream for a given druid" do
      # service.get_datastream_md(druid, ds_id)
    end
  
  end
  

end