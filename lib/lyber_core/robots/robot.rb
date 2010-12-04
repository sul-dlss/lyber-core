# == Usage 
#   ruby_cl_skeleton [options] source_file
#
#   For help use: ruby_cl_skeleton -h

module LyberCore
  module Robots
    require 'optparse'
    require 'ostruct'

    # ===== Usage
    # User defined robots should derive from this class and override the #process_item method
    class Robot
      attr_accessor :workflow_name
      attr_accessor :workflow_step
      
      # A LyberCore::Robots::Workflow object
      attr_accessor :workflow 
      attr_accessor :collection_name
      attr_accessor :workspace
      attr_accessor :args
      attr_accessor :options


      # Available options
      # - :collection_name - The collection this workflow should work with.  
      #   Defined as a subdirectory within ROBOT_ROOT/config/workflows/your_workflow/your_collection
      # - :workspace - Full path of where to find content for a particular workflow
      # - :logfile - Where to write log messages
      # - :loglevel - Level of logging from 0 - 4 where 0 = DEBUG and 4 = FATAL
      def initialize(workflow_name, workflow_step, args = {})
        @workflow_name = workflow_name
        @workflow_step = workflow_step
        #TODO: Replace 'dor.' with actual repository ID
        @collection_name = args[:collection_name]
        @opts = args

        if args[:logfile]
          LyberCore::Log.set_logfile(args[:logfile])
        else
          FileUtils.mkdir(File.join(ROBOT_ROOT, 'log')) unless(File.exists?(File.join(ROBOT_ROOT, 'log')))
          robot_logfile = File.join(ROBOT_ROOT,'log',workflow_step+'.log')
          LyberCore::Log.set_logfile(robot_logfile)
        end

        LyberCore::Log.set_level(args[:loglevel]) if args[:loglevel] 
      
        # Set defaults
        @options = OpenStruct.new
        self.parse_options
        self.create_workflow
        self.set_workspace

        @msg_queue_name = "/queue/#{@workflow.repository}.#{@workflow_name}.#{@workflow_step}"
      end
      
      # Some workflows require a directory where their content lives
      # If a robot is invoked with a :workspace => true option, its @workspace
      # should be set from the value in 
      def set_workspace
        if(@opts[:workspace])
          @workspace = LyberCore::Robots::Workspace.new(@workflow_name, @collection_name)
          LyberCore::Log.debug("workspace = #{workspace.inspect}")
        end
      end
      
      # Create the workflow at instantiation, not when we start running the robot.
      # That way we can do better error checking and ensure that everything is going
      # to run okay before we actually start things.
      def create_workflow
        
        unless defined?(WORKFLOW_URI)
          LyberCore::Log.fatal "FATAL: WORKFLOW_URI is not defined"
          LyberCore::Log.fatal "Usually this is a value like 'http://lyberservices-dev.stanford.edu/workflow'"
          LyberCore::Log.fatal "Usually you load it by setting ROBOT_ENVIRONMENT when you invoke your robot"
          raise "WORKFLOW_URI is not set! Do you need to set your ROBOT_ENVIRONMENT value?"
        end
        LyberCore::Log.debug("About to instatiate a Workflow object
            -- LyberCore::Robots::Workflow.new(#{@workflow_name},#{collection_name}")
        @workflow = LyberCore::Robots::Workflow.new(@workflow_name, {:logger => @logger, :collection_name => @collection_name})
        
      end
    
      # == Create a new workflow 
      def start_standalone()
        
        begin
          LyberCore::Log.debug("Running as standalone...")
          queue = establish_queue()
          process_queue(queue)
        # TODO: Implement a FatalError class
        # rescue LyberCore::Exceptions::FatalError => e
        #   LyberCore::Log.fatal("e.msg")
        #   exit
        rescue LyberCore::Exceptions::EmptyQueue
          LyberCore::Log.info("Empty queue -- no objects to process")
        rescue Exception => e
          LyberCore::Log.exception(e)
        end
      end
      
      def start_master()
        LyberCore::Log.debug("Running as master...")
        stomp = Stomp::Client.new(MSG_BROKER_CONFIG)
        queue = establish_queue()
        while work_item = queue.next_item do
          stomp.begin("enqueue_#{work_item.druid}")
          begin
            stomp.publish(@msg_queue_name, work_item, :persistent => true)
            #TODO: Set work item status to queued.
            stomp.commit("enqueue_#{work_item.druid}")
          rescue
            stomp.abort("enqueue_#{work_item.druid}")
          end
        end
      end
      
      def start_slave()
        LyberCore::Log.debug("Running as slave...")
        stomp = Stomp::Client.new(MSG_BROKER_CONFIG)
        stomp.subscribe(@msg_queue_name, :ack => :client) do |msg|
          begin
            queue = @workflow.queue(@workflow_step)
            queue.enqueue_druids([msg.body.strip])
            process_queue(queue)
            # TODO: Generate statistics about the work
          rescue Exception => e
            LyberCore::Log.error(e.msg)
            LyberCore::Log.error(e.backtrace.join("\n"))
          ensure
            stomp.acknowledge(msg)
          end
        end
        # TODO: Decouple work_item, work_queue, and identity logic
        # TODO: Figure out how to decide when to stop listening
        # But for now...
        stomp.join()
      end
      
      def start()
        LyberCore::Log.debug("Starting robot...")
        if @options.mode == :slave
          start_slave()
        elsif @options.mode == :master
          start_master()
          start_slave()
        else
          start_standalone()
        end
      end

      # Generate a queue of work items based from file, druid, or service
      def establish_queue()
        queue = @workflow.queue(@workflow_step)
    
        # If we have arguments, parse out the parts that indicate druids
        if(@options.file or @options.druid)
          queue.enqueue_druids(get_druid_list)
        else
          queue.enqueue_workstep_waiting()
        end
        return queue
      end
      
      # Generate a list of druids to process
      def get_druid_list
      
        druid_list = Array.new
        
        # append any druids passed explicitly
        if(@options.druid)
          druid_list << @options.druid
        end
      
        # identifier list is in a file
         if (@options.file && File.exist?(@options.file))
          File.open(@options.file) do |file|
            file.each_line do |line|
              druid = line.strip
              if (druid.length > 0)
                druid_list << druid
              end
            end
          end
        end
      
        return druid_list
      end

      def process_queue(queue)
        while work_item = queue.next_item do
          process_work_item(work_item)
        end
        queue.print_stats()
      end
    
      def process_work_item(work_item)
        begin
          #call overridden method
          process_item(work_item)
          work_item.set_success
        rescue LyberCore::Exceptions::FatalError => fatal_error
          # ToDo cleanup/rollback transaction
          raise fatal_error
        rescue LyberCore::Exceptions::ItemError => item_error
          # ToDo cleanup/rollback transaction
          LyberCore::Log.exception(item_error)
          work_item.set_error(item_error.inspect)
        rescue Exception => e
          # ToDo cleanup/rollback transaction
          item_error = LyberCore::Exceptions::ItemError.new(work_item.druid, "Unexpected item error", e)
          LyberCore::Log.exception(item_error)
          work_item.set_error(item_error.inspect)
        end
      end
      
      # Override this method in your robot instance.  The method in this base class will throw an exception if it is not overriden.
      def process_item(work_item)
        #to be overridden by child classes
        raise 'You must implement this method in your subclass'
      end 
      
    # ###########################
    # command line option parsing 
  
        def parse_options
        
          options = {}

          o = OptionParser.new do |opts|
            opts.banner = "Usage: example.rb [options]"
            opts.separator ""

            opts.on("-d DRUID", "--druid DRUID", "Pass in a druid to process") do |d|
              @options.druid = d
            end
          
            opts.on("-f", "--file FILE", "Pass in a file of druids to process") do |f|
              @options.file = f
            end
            
            opts.on("-m MODE", "--mode MODE", "Specify the mode to run in") do |m|
              case m
              when "master"
                @options.mode = :master
              when "slave"
                @options.mode = :slave
              when "default"
                @options.mode = :default
              else
                raise OptionParser::InvalidArgument, "Invalid mode: #{m}"
              end
            end
          
          end
        
          # Parse the command line options and ignore anything not specified above
          begin
            o.parse!
          rescue OptionParser::InvalidOption => e
            LyberCore::Log.debug("e.inspect")
          rescue OptionParser::ParseError => e
            LyberCore::Log.error("Couldn't parse options: #{e.backtrace}") 
            raise e
          end
        
        end

        # def output_options
        #   puts "Options:\n"
        # 
        #   @options.marshal_dump.each do |name, val|        
        #     puts "  #{name} = #{val}"
        #   end
        # end
        # 
        # def output_help
        #   output_version
        #   RDoc::usage() #exits app
        # end
        # 
        # def output_usage
        #   RDoc::usage('usage') # gets usage from comments above
        # end
        # 
        # def output_version
        #   puts "#{File.basename(__FILE__)} version #{VERSION}"
        # end
  
    # ##################################
    # end of command line option parsing 
    # ##################################
  
    end # end of class
  end # end of Robots module
end # end of LyberCore module