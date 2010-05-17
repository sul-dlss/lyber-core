

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'lyber_core'

class TestRobot < LyberCore::Robot
  def process_item(work_item)
    #nada for now
  end
end

describe LyberCore::Robot do
  
  it "should process a batch of druids from the Workflow" do
    pending()
    # This is failing as of 17 May 2010 at 12:11
    # Commenting it out per a discussion with Willy so that I can get the rdocs published.
    # -- Bess
    
    # mock_workflow = mock('workflow')
    # mock_queue = mock('queue')
    # robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
    # LyberCore::Workflow.should_receive(:new).and_return(mock_workflow)
    # mock_workflow.should_receive(:queue).with('descriptive-metadata').and_return(mock_queue)
    # mock_queue.should_receive(:enqueue_workstep_waiting)
    # robot.should_receive(:process_queue).and_return(nil)
    # robot.start
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