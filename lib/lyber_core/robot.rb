module LyberCore
  
  class Robot
    attr_accessor :workflow
    attr_accessor :workspace
    attr_accessor :opts

    # available options
    # :collection_name
    # :workspace
    # :druid_ref
    
    def initialize(workflow_name, workflow_step, opts = {})
      @workflow_name = workflow_name
      @workflow_step = workflow_step
      @collection_name = opts[:collection_name]
      @opts = opts
    end
    
    def start()
      @workflow = LyberCore::Workflow.new(@workflow_name, @collection_name)
      if(@opts[:workspace] == true)
        @workspace = LyberCore::Workspace.new(@workflow_name, @collection_name)
      end
      queue = @workflow.queue(@workflow_step)
      if(ARGV.size > 0)
        queue.enqueue_druids(get_druid_list(ARGV[0]))
      else
        queue.enqueue_workstep_waiting()
      end
      process_queue(queue)
    end

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
    
    def process_item(work_item)
      #to be overridden by child classes
      raise 'You must implement this method in your subclass'
    end 
    
  end
  
end