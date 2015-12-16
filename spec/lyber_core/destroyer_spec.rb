require 'spec_helper'
require 'dor-services'
require File.expand_path(File.dirname(__FILE__) + "/../fixtures/config/environments/test.rb")
require 'fakeweb'

describe LyberCore::Destroyer do

  before :all do
    FakeWeb.clean_registry
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
      expect(@dfo.repository).to eql("dor")
      expect(@dfo.workflow).to eql("googleScannedBookWF")
      expect(@dfo.registration_robot).to eql("register-object")
    end

    it "knows its workflow URL" do
      expect(Dor::Config.workflow.url).to eql("http://lyberservices-dev.stanford.edu/workflow")
    end

    it "can get all the druids for a workflow" do
      expect(@dfo.druid_list).to match_array(%w(druid:kv369fp5449 druid:ch639ch2025 druid:nr812fr7912 druid:qj817sf0765 druid:jx368wq5745 druid:gv079bw9958 druid:sz826gb8674 druid:mg674rv7413 druid:tv840tf8420 druid:dx718jt7616 druid:kw310kp8493))
    end

  end

  context "delete from fedora" do

    it "has a method that tells it to delete the druids" do
      expect(@dfo).to respond_to(:delete_druids)
    end

  end
end