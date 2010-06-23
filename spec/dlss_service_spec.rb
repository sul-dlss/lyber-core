require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'dlss_service'

describe DlssService do
  
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