require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'

describe LyberCore::Robots::Workspace do
  
  ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")      
  require "#{ROBOT_ROOT}/config/environments/test.rb"
  
  before(:all) do
    @workflow_name = "googleScannedBookWF"
    @druid = "druid:foo"
    @workspace = LyberCore::Robots::Workspace.new(@workflow_name)
  end
  
  it "has a workflow" do
    @workspace.workflow_name.should eql(@workflow_name)
  end
  
  it "constructs a workspace_base without a collection name" do
    @workspace.workspace_base.should eql("#{WORKSPACE_HOME}/#{@workflow_name}")
  end
  
  it "constructs a workspace_base with a collection name" do
    collection_name = "my_collection"
    ws = LyberCore::Robots::Workspace.new(@workflow_name, collection_name)
    ws.workspace_base.should eql("#{WORKSPACE_HOME}/#{@workflow_name}/#{collection_name}")
  end
  
  it "constructs a filepath for the original GRIN download" do
    @workspace.original_dir(@druid).should eql("#{@workspace.workspace_base}/original/foo")
  end
  
  it "constructs a filepath for the content" do
    @workspace.content_dir(@druid).should eql("#{@workspace.workspace_base}/content/foo")
  end
  
  it "constructs a filepath for the metadata" do
    @workspace.metadata_dir(@druid).should eql("#{@workspace.workspace_base}/metadata/foo")
  end
  
end 