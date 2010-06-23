# == Usage 
#   ruby_cl_skeleton [options] source_file
#
#   For help use: ruby_cl_skeleton -h

module LyberCore
  
  require 'optparse'

  # ===== Usage
  # User defined robots should derive from this class and override the #process_item method
  class Robot
    attr_accessor :workflow
    attr_accessor :workspace
    attr_accessor :args
    attr_accessor :options

    # ==== Available options
    # - :collection_name - The collection this workflow should work with.  
    #   Defined as a subdirectory within ROBOT_ROOT/config/workflows/your_workflow/your_collection
    # - :workspace - Full path of where to find content for a particular workflow
    def initialize(workflow_name, workflow_step, args = {})
      @workflow_name = workflow_name
      @workflow_step = workflow_step
      @collection_name = args[:collection_name]
      
      puts ARGV.inspect
      @argv = ARGV
      
      @args = args
      
      
      puts "args = #{args.inspect}"

      # Set defaults
      @options = OpenStruct.new
      @options.verbose = false
      @options.quiet = false
      self.parse_options
      
      puts "options = #{@options.inspect}"
    end
    
    def start()
      @workflow = LyberCore::Workflow.new(@workflow_name, @collection_name)
      # if(@opts[:workspace] == true)
      #   @workspace = LyberCore::Workspace.new(@workflow_name, @collection_name)
      # end
      queue = @workflow.queue(@workflow_step)
      
      # If we have arguments, parse out the parts that indicate druids
      if(ARGV.size > 0)
        queue.enqueue_druids(get_druid_list(ARGV[0]))
      else
        queue.enqueue_workstep_waiting()
      end
      process_queue(queue)
    end

    # TODO: ignore flags that are passed in like "--format pretty or -f"
    # --pid PID:NUMBER or --file filename
    def get_druid_list(druid_ref)
      druid_list = Array.new
      # identifier list is in a file
       if (File.exist?(druid_ref))
        File.open(druid_ref) do |file|
          file.each_line do |line|
            druid = line.strip
            if (druid.length > 0)
              druid_list << druid
            end
          end
        end
      # identifier was specified on the command line
      else
          druid_list << druid_ref
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
        OptionParser.new do |opts|
          opts.banner = "Usage: example.rb [options]"

          opts.on("-d DRUID", "--druid DRUID", "Pass in a druid to process") do |d|
            @options.druid = d
          end
        end.parse!
        
      end

      def output_options
        puts "Options:\n"

        @options.marshal_dump.each do |name, val|        
          puts "  #{name} = #{val}"
        end
      end

      # True if required arguments were provided
      def arguments_valid?
        # TO DO - implement your real logic here
        true if @arguments.length == 1 
      end

      # Setup the arguments
      def process_arguments
        
      end

      def output_help
        output_version
        RDoc::usage() #exits app
      end

      def output_usage
        RDoc::usage('usage') # gets usage from comments above
      end

      def output_version
        puts "#{File.basename(__FILE__)} version #{VERSION}"
      end

      def process_command
        # TO DO - do whatever this app does

        #process_standard_input # [Optional]
      end

      def process_standard_input
        input = @stdin.read      
        # TO DO - process input

        # [Optional]
        # @stdin.each do |line| 
        #  # TO DO - process each line
        #end
      end
  
  # ##################################
  # end of command line option parsing 
  # ##################################
  
  end # end of class
  
end # end of module