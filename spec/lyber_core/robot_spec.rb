

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'lyber_core'

class TestRobot < LyberCore::Robot
  def process_item(work_item)
    #nada for now
  end
end

describe LyberCore::Robot do
  
  it "has default values for its options" do
    mock_workflow = mock('workflow')
    mock_queue = mock('queue')
    robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
    robot.options.verbose.should eql(false)
    robot.options.quiet.should eql(false)
  end
  
  it "can accept a single druid for processing" do
    mock_workflow = mock('workflow')
    mock_queue = mock('queue')
    ARGV << "--druid=sdrtwo:blah"
    robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
    robot.get_druid_list[0].should eql("sdrtwo:blah")
  end
  
  # it "can accept a file of druids for processing" do
  #   mock_workflow = mock('workflow')
  #   mock_queue = mock('queue')
  #   ARGV << "--file=fakefile"
  #   robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
  #   puts robot.get_druid_list
  # end
  
  it "should process a batch of druids from the Workflow" do    
    mock_workflow = mock('workflow')
    mock_queue = mock('queue')
    robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
    LyberCore::Workflow.should_receive(:new).and_return(mock_workflow)
    mock_workflow.should_receive(:queue).with('descriptive-metadata').and_return(mock_queue)
    ARGV.stub!(:size).and_return(0)
    mock_queue.should_receive(:enqueue_workstep_waiting)
    robot.should_receive(:process_queue).and_return(nil)
    robot.start
  end

  it "should process queue of objects" do

    mock_queue = mock('queue')
    mock_item = mock('item')
    mock_mdutils = mock('mdutils')
    mock_dorservice = mock('dorservice')
    robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')

    #Return the mock item the first time, return nil the second time to stop the while loop
    mock_queue.should_receive(:next_item).and_return(mock_item, nil)
    mock_queue.should_receive(:print_stats)

    #inside the while loop
    mock_item.should_receive(:set_success)

    robot.should_receive(:process_item)

    robot.process_queue(mock_queue)

  end
  
end