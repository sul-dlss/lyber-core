require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'net/https'

require 'action_controller'
require 'action_controller/test_process'


describe Dor::SuriService do
  
  before(:all) do
    with_warnings_suppressed do
      MINT_SURI_IDS = true
      SURI_URL = 'http://some.suri.host:8080'
      ID_NAMESPACE = 'druid'
      SURI_USER = 'suriuser'
      SURI_PASSWORD = 'suripword'
    end
  end
  
  
  # it "should mint a druid" do
  #   id = Dor::SuriService.mint_id
  #   puts id
  #   id.should_not be_nil
  #   id.should =~ /^druid:/
  # end
  describe "an enabled SuriService" do
        
    it "should mint a druid using LyberCore::Connection" do
      LyberCore::Connection.should_receive(:post).with("#{SURI_URL}/suri2/namespaces/#{ID_NAMESPACE}/identifiers", nil,
                                                {:auth_user => SURI_USER, :auth_password => SURI_PASSWORD}).and_return('somestring')
                                                
      Dor::SuriService.mint_id.should == "#{ID_NAMESPACE}:somestring"                                         
    end
  
    it "should throw log an error and rethrow the exception if Connect fails." do
      e = "thrown exception"
      ex = Exception.new(e)
      LyberCore::Connection.should_receive(:post).with("#{SURI_URL}/suri2/namespaces/#{ID_NAMESPACE}/identifiers", nil,
                                                {:auth_user => SURI_USER, :auth_password => SURI_PASSWORD}).and_raise(e)
                                                
      Rails.stub_chain(:logger, :error).with("Unable to mint id from suri: #{e}")
      lambda{ Dor::SuriService.mint_id }.should raise_error(Exception, "thrown exception")
    end
    
  end
  
  it "should use the Fedora->nextpid service if calls to SURI are disabled" do
    with_warnings_suppressed{MINT_SURI_IDS = false}
    Fedora::Repository.stub_chain(:instance, :nextid).and_return('pid:123')
    
    Dor::SuriService.mint_id.should == 'pid:123'
  end
  
  # it "should mint a real id in an integration test" do
  #   with_warnings_suppressed do
  #     MINT_SURI_IDS = true
  #     ID_NAMESPACE = 'druid'
  #     SURI_URL = 'http://lyberservices-test.stanford.edu:8080'
  #     SURI_USER = 'hydra-etd'
  #     SURI_PASSWORD = 'lyberteam'
  #   end
  #   
  #    Dor::SuriService.mint_id.should == ''
  # end
  
end