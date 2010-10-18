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
        @collection_name = args[:collection_name]      
        @opts = args
        
        LyberCore::Log.set_logfile(args[:logfile]) if args[:logfile] 
        LyberCore::Log.set_level(args[:loglevel]) if args[:loglevel] 
      
        # Set defaults
        @options = OpenStruct.new
        @options.verbose = false
        @options.quiet = false
        self.parse_options
        self.create_workflow
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
      def start()
        
        LyberCore::Log.debug("Starting robot...")
        if(@opts[:workspace] == true)
          @workspace = LyberCore::Robots::Workspace.new(@workflow_name, @collection_name)
          LyberCore::Log.debug("workspace = #{workspace.inspect}")
        end
        queue = @workflow.queue(@workflow_step)
      
        # If we have arguments, parse out the parts that indicate druids
        if(@options.file or @options.druid)
          queue.enqueue_druids(get_druid_list)
        else
          queue.enqueue_workstep_waiting()
        end
        process_queue(queue)
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
          begin
            #call overridden method
            process_item(work_item)
            work_item.set_success
          rescue Exception => e
            work_item.set_error(e)
          end
        end
        queue.print_stats()
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
          
          end
        
          # Parse the command line options and ignore anything not specified above
          begin
            o.parse!
          rescue OptionParser::ParseError => e
            puts e
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