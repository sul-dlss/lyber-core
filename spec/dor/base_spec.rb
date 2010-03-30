
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'active_fedora'

class Local < Dor::Base
  
end

describe Dor::Base do
  
  it "should be of Type ActiveFedora::Base" do
    with_warnings_suppressed do
      MINT_SURI_IDS = false
      SOLR_URL = "http://solr.edu"
      FEDORA_URL = "http://fedora.edu"
    end
    Rails.stub_chain(:logger, :error)
    ActiveFedora::SolrService.register(SOLR_URL)
    Fedora::Repository.register(FEDORA_URL)
    Fedora::Repository.stub!(:instance).and_return(stub('frepo').as_null_object)
    
    b = Dor::Base.new
    b.should be_kind_of(ActiveFedora::Base)
    
    l = Local.new
    l.should be_kind_of(Dor::Base)
  end
  
end