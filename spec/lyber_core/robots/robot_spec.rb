require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'lyber_core'
require 'fakeweb'
require File.expand_path(File.dirname(__FILE__) + "/test_robot.rb")  

describe LyberCore::Robots::Robot do
  
  with_warnings_suppressed do
    ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/")   
  end   
  require "#{ROBOT_ROOT}/config/environments/test.rb"
    
  context "environment loading" do
    
    before(:all) do
      wf_name = "sdrIngestWF"
      wf_step = "populate-metadata"
      collection = "baz"
      valid_logfile = "/tmp/fakelog.log"
    end
      
    # it "raises an exception if WORKFLOW_URI is not defined" do
    #   pending "This test passes when run on its own, but undefining WORKFLOW_URI seems to break the other tests"
    #   Object.send(:remove_const, :WORKFLOW_URI) if defined? WORKFLOW_URI
    #   lambda { robot = TestRobot.new("sdrIngestWF", "populate-metadata", :logfile => valid_logfile) }.should raise_exception(/WORKFLOW_URI is not set/)        
    # end
      
  end
  
  context "initial state" do
    
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    collection = "baz"
    
    before :each do
      require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    end
  
    it "has accessor methods" do
      robot = TestRobot.new(wf_name, wf_step, :collection_name => collection)
      robot.workflow_name.should eql(wf_name)
      robot.workflow_step.should eql(wf_step)
      robot.collection_name.should eql(collection)
    end
    
    it "can tell us what environment it's running in" do
      pending
      robot = TestRobot.new(wf_name, wf_step, :collection_name => collection)
      robot.env.should eql("test") 
    end
  
    # it "has a workflow after it has started" do
    #   ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..")      
    #   robot = TestRobot.new("googleScannedBookWF","register-object", :collection_name => collection)
    #   robot.start
    #   puts robot.workflow
    # end
    
  end

  context "logging" do
    
    require 'dor_service'
    require 'dlss_service'
    require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    
    wf_name = "sdrIngestWF"
    wf_step = "populate-metadata"
    valid_logfile = "/tmp/fakelog.log"
    invalid_logfile = "/zzxx/fakelog.log"
   
    before :each do
      LyberCore::Log.restore_defaults
    end
  
    it "can set the location of the log file when it is created" do
      robot = TestRobot.new(wf_name, wf_step, :logfile => valid_logfile)
      LyberCore::Log.logfile.should eql(valid_logfile)
    end
  
    it "can set the log level when it is created" do
      robot = TestRobot.new(wf_name, wf_step, 
        :loglevel => Logger::DEBUG, 
        :logfile => valid_logfile)
      LyberCore::Log.level.should eql(Logger::DEBUG)       
    end
      
  end
      
  context "workflow" do
      
      it "can inspect its workflow object" do
        robot = TestRobot.new("sdrIngestWF", "populate-metadata")
        robot.workflow.repository.should eql("sdr")
      end    
  end
      
  context "empty workflow queue" do
    
    before :all do
      FakeWeb.allow_net_connect = false
    end
    
    after :all do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = true
    end
    
    it "does not report an error if it encounters an empty workflow queue" do
      repository = "dor"
      workflow = "googleScannedBookWF"
      completed = "google-download"
      waiting = "process-content"
      FakeWeb.register_uri(:get, %r|lyberservices-dev\.stanford\.edu/|,
        :body => "<objects count=\"0\" />")
      robot = TestRobot.new(workflow, waiting)
      robot.should_not_receive(:process_queue)
      robot.start
    end
    
  end    
  
        
  context "command line options" do
    
    before(:all) do
      @workflow_name = "googleScannedBookWF"
    end
    
    it "can accept a single druid for processing" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--druid=sdrtwo:blah"
      robot = TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.get_druid_list[0].should eql("sdrtwo:blah")
    end
    
    it "can accept a file of druids for processing" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--file=fakefile"
      robot = TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.options.file.should eql("fakefile")
    end
    
    # Cucumber passes "--format pretty" as an argument, which can make the robots fail unless
    # we check for it. 
    it "shouldn't fail when run by cucumber" do
      mock_workflow = mock('workflow')
      mock_queue = mock('queue')
      ARGV << "--format pretty"
      lambda { TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain') }.should_not raise_exception()
    end
    
    it "can override the default logfile via the commandline" do
      pending
    end
    
    it "can override the default log level via the commandline" do
      pending
    end
    
    it "can accept both a file of druids for processing and a logfile on a single command line" do
      pending
    end
    
    it "defaults to standalone mode" do
      robot = TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.options.mode.should be_nil
    end
    
    it "can recognize master mode" do
      ARGV << "--mode=master"
      robot = TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.options.mode.should eql(:master)
    end
    
    it "can recognize slave mode" do
      ARGV << "--mode=slave"
      robot = TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
      robot.options.mode.should eql(:slave)
    end
    
    it "should complain about an invalid mode" do
      ARGV << "--mode=invalid"
      lambda { TestRobot.new(@workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain') }.should raise_exception(OptionParser::InvalidArgument)
    end
    
  end
  
  context "workspace" do
    
    it "can be invoked with a workspace" do
      workflow_name = "googleScannedBookWF"
      robot = TestRobot.new(workflow_name, "google-download", :workspace => true)
      robot.workspace.workspace_base.should eql("#{WORKSPACE_HOME}/#{workflow_name}")
    end
    
  end
  
  context "other" do
      
      workflow_name = "googleScannedBookWF"
  
      it "processes a batch of druids from the Workflow" do   
        
        require File.expand_path(File.dirname(__FILE__) + "/../../fixtures/config/environments/test.rb")  
    
        robot = TestRobot.new(workflow_name, "descriptive-metadata", :collection_name => 'publicDomain')
        # puts robot.workflow.inspect
        # puts robot.workflow.queue('descriptive-metadata')
    
        # mock_workflow = mock('workflow')
        # mock_queue = mock('queue')
        # robot = TestRobot.new('googleScannedBook', 'descriptive-metadata', :collection_name => 'publicDomain')
        # LyberCore::Robots::Workflow.should_receive(:new).and_return(mock_workflow)
        # mock_workflow.should_receive(:queue).with('descriptive-metadata').and_return(mock_queue)
        # ARGV.stub!(:size).and_return(0)
        # mock_queue.should_receive(:enqueue_workstep_waiting)
        # robot.should_receive(:process_queue).and_return(nil)
        # robot.start
      end
    
      it "processes a queue of objects" do
    
        mock_queue = mock('queue')
        mock_item = mock('item')
        mock_mdutils = mock('mdutils')
        mock_dorservice = mock('dorservice')
        robot = TestRobot.new(workflow_name, 'descriptive-metadata', :collection_name => 'publicDomain')
    
        #Return the mock item the first time, return nil the second time to stop the while loop
        mock_queue.should_receive(:next_item).and_return(mock_item, nil)
        #mock_queue.should_receive(:print_stats)
    
        #inside the while loop
        mock_item.should_receive(:set_success)
    
        robot.should_receive(:process_item)
    
        robot.process_queue(mock_queue)
    
      end
      
      it "keeps going even if it encounters an error in one of the objects" do
        druid = 'druid:xy123'
        my_error = Errno::EACCES.new("my error")
        mock_item_bad = mock('baditem')
        #mock_item_bad.should_receive(:druid).and_return(druid)
        mock_item_bad.should_receive(:set_error).with(my_error).and_return(true)

        mock_item_good = mock('gooditem')
        mock_item_good.should_receive(:set_success).and_return(true)

        mock_queue = mock('queue')
        mock_queue.should_receive(:next_item).and_return(mock_item_bad, mock_item_good, nil)
        # mock_queue.should_receive(:print_stats)

        robot = TestRobot.new(workflow_name, 'descriptive-metadata')
        robot.should_receive(:process_item).with(mock_item_bad).and_raise(my_error)
        robot.should_receive(:process_item).with(mock_item_good)
        robot.process_queue(mock_queue)
      end
    
    end
  
    context "messaging" do

      it "should post druids to the queue in master mode" do
        mock_stomp = mock('stomp')
        mock_stomp.should_receive(:begin).twice
        mock_stomp.should_receive(:publish).twice.and_return(true)
        mock_stomp.should_receive(:commit).twice
        
        mock_queue = mock('queue')

        mock_item = mock('item')
        mock_item.should_receive(:druid).any_number_of_times.and_return("foo:bar")
        mock_item.should_receive(:set_status).with('queued').and_return(true)

        mock_item2 = mock('item2')
        mock_item2.should_receive(:druid).any_number_of_times.and_return("foo:baz")
        mock_item2.should_receive(:set_status).with('queued').and_return(true)
        
        mock_queue.should_receive(:next_item).and_return(mock_item, mock_item2, nil)
        robot = TestRobot.new('googleScannedBookWF', 'descriptive-metadata')
        robot.stub!(:establish_queue).and_return(mock_queue)
        robot.start_master(mock_stomp)
      end
      
      it "should time out if the server is unavailable in master mode" do
        mock_stomp = double('stomp')
        mock_stomp.should_receive(:begin).once
        mock_stomp.stub(:publish) do
          sleep(MSG_BROKER_TIMEOUT+2)
        end

        mock_item = mock('item')
        mock_item.should_receive(:druid).any_number_of_times.and_return("foo:bar")

        mock_queue = mock('queue')
        mock_queue.should_receive(:next_item).and_return(mock_item)
        
        robot = TestRobot.new('googleScannedBookWF', 'descriptive-metadata')
        robot.stub!(:establish_queue).and_return(mock_queue)
        expect { robot.start_master(mock_stomp) }.to raise_error(LyberCore::Exceptions::FatalError)
      end
      
      it "should read druids from the queue and process them in slave mode and time out" do
        mock_message1 = mock('message1')
        mock_message1.should_receive(:command).any_number_of_times.and_return('MESSAGE')
        mock_message1.should_receive(:headers).and_return({'message-id'=>'message1'})
        mock_message1.should_receive(:body).any_number_of_times.and_return('foo:bar')

        mock_message2 = mock('message2')
        mock_message2.should_receive(:command).any_number_of_times.and_return('MESSAGE')
        mock_message2.should_receive(:headers).and_return({'message-id'=>'message2'})
        mock_message2.should_receive(:body).any_number_of_times.and_return('foo:baz')

        # Message 3 should never be received by the client unless the timeout fails
        # We set it up anyway so that a timeout failure is reported as a timeout failure
        # and not as a NoMethodError
        mock_message3 = mock('message3')
        mock_message3.should_receive(:command).any_number_of_times.and_return('MESSAGE')
        mock_message3.should_receive(:headers).at_most(1).times.and_return({'message-id'=>'message3'})
        mock_message3.should_receive(:body).any_number_of_times.and_return('foo:quux')

        mock_stomp = double('stomp')
        messages = [[0, mock_message1], [0, mock_message2], [MSG_BROKER_TIMEOUT+2, mock_message3]]
        mock_stomp.stub(:receive) do
          (sleep_time,return_value) = messages.shift
          sleep(sleep_time) && return_value
        end
        mock_stomp.should_receive(:receive).exactly(3).times
        mock_stomp.should_receive(:subscribe).once.with('/queue/dor.googleScannedBookWF.descriptive-metadata', anything())
        mock_stomp.should_receive(:ack).twice.and_return(true)
        
        robot = TestRobot.new('googleScannedBookWF', 'descriptive-metadata')
        robot.should_receive(:process_item).twice
        start_time = Time.now
        robot.start_slave(mock_stomp)
        elapsed_time = Time.now - start_time
        elapsed_time.should be >= MSG_BROKER_TIMEOUT
        elapsed_time.should be <= MSG_BROKER_TIMEOUT+1.5
      end
      
    end

end