require 'spec_helper'

describe LyberCore::Robots::Workspace do
  
  with_warnings_suppressed do
    ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")   
  end   
  require "#{ROBOT_ROOT}/config/environments/test.rb"
  
  before(:all) do
    @workflow_name = "googleScannedBookWF"
    @druid = "druid:foo"
    @workspace = LyberCore::Robots::Workspace.new(@workflow_name)
  end
  
  it "knows the value of WORKSPACE_HOME" do
    Dor::Config.robots.workspace.should eql(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/workspace_home'))
  end
  
  it "has a workflow" do
    @workspace.workflow_name.should eql(@workflow_name)
  end
  
  it "can set workspace_home" do
    wh = @workspace.set_workspace_home
    wh.should eql(Dor::Config.robots.workspace)
  end
  
  it "constructs a workspace_base without a collection name" do
    @workspace.workspace_base.should eql("#{Dor::Config.robots.workspace}/#{@workflow_name}")
  end
  
  it "constructs a workspace_base with a collection name" do
    collection_name = "my_collection"
    ws = LyberCore::Robots::Workspace.new(@workflow_name, collection_name)
    ws.workspace_base.should eql("#{Dor::Config.robots.workspace}/#{@workflow_name}/#{collection_name}")
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
  
  it "can normalize a druid" do
    @workspace.normalized_druid(@druid).should eql("foo")
  end
  
  it "ensures the existance of the workspace" do
    dir = "/tmp"
    @workspace.ensure_workspace_exists(dir)
  end
  
  it "raises an error if it cannot create a workspace" do
    pending
    dir = "/foo"
    lambda { @workspace.ensure_workspace_exists(dir) }.should raise_exception
  end
  
end 