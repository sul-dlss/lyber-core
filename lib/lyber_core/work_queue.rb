require 'dor_service'
require 'yaml'

module LyberCore
  # Represents a set of workitem objects to be processed by a given step of a workflow
  class WorkQueue

    # The workflow that this queue is a part of
    attr_reader :workflow
    # The step in the workflow that is being processed against this queue
    attr_reader :workflow_step
    # The workflow step that should have already been completed for the workitem object
    attr_reader :prerequisite
    # The maximum number of workitem objects to process in one run of a robot
    attr_reader :batch_limit
    # The maximum number of errors to allow before terminating the batch run
    attr_reader :error_limit
    # The array of primary identifiers for the workitem objects to be processed
    attr_reader :druids
    # An alternative identitier to be used when druids are not yet available (e.g at registration)
    attr_reader :identifier_name
    attr_reader :identifier_values
    # The tally of how many items have been processed
    attr_reader :item_count
    attr_accessor :success_count
    attr_accessor :error_count
    # The timings for the batch run
    attr_reader :start_time
    attr_reader :end_time
    attr :elapsed_time


    # Create a new WorkQueue object for the specified step,
    # save a pointer to the parent WorkFlow,
    # start the timer,
    # read in the configuration information for the work step
    def initialize(workflow=nil, workflow_step=nil)
      @start_time = Time.new
      print "\nStarting #{workflow_step} at #{@start_time}\n"
      @workflow = workflow
      @workflow_step = workflow_step
      @item_count = 0
      @success_count = 0
      @error_count = 0
      # nil arguments should only be used if in test mode
      if (workflow.nil? || workflow_step.nil?)
        @batch_limit = 2
        @error_limit = 1
        return
      end
      begin
        config_file = File.join(@workflow.workflow_config_dir, 'process-config.yaml')
        process_config = YAML.load_file(config_file)
        @prerequisite = process_config[@workflow_step]['prerequisite']
        @batch_limit = process_config[@workflow_step]['batch_limit']  
        @error_limit = process_config[@workflow_step]['error_limit']
      rescue Exception => e
        puts "error processing config_file #{config_file}"
        puts "error details - #{e.inspect}"
        puts e.backtrace
        puts  process_config.inspect
        raise "could not initialize queue for #{@workflow_step}"
      end
    end

    # Explicitly specify a set of druids to be processed by the workflow step
    def enqueue_druids(druid_array)
      @druids = druid_array
    end

    # Obtain the set of druids to be processed using a database query
    # to obtain the repository objects that are awaiting this step
    def enqueue_workstep_waiting()
      object_list_xml = DorService.get_objects_for_workstep(workflow.repository, workflow.workflow_id, @prerequisite, @workflow_step)
      @druids = DorService.get_druids_from_object_list(object_list_xml)
    end

    # Use an alternative set of identifiers as the basis of this queue
    # e.g. use array of barcodes as basis for google register-object robot
    def enqueue_identifiers(identifier_name, identifier_values)
      @identifier_name = identifier_name
      @identifier_values = identifier_values
    end

    # Get the next WorkItem to be processed by the robot for the workflow step
    def next_item()
      if (@item_count >= @batch_limit )
        puts "Batch limit of #{@batch_limit} items reached"
        return nil
      end
      if (@error_count >= @error_limit )
        puts "Error limit of #{@error_limit} items reached"
        return nil
      end
      work_item =  LyberCore::WorkItem.new(self)
      if (@druids)
        return nil if (@item_count >= @druids.length)
        work_item.druid= @druids[@item_count]
      elsif (@identifier_values)
        return nil if (@item_count >= @identifier_values.length)
        work_item.identifier_add(@identifier_name,@identifier_values[@item_count])
      else
        return nil
      end
      @item_count += 1
      return  work_item
    end

    # Output the batch's timings and other statistics to STDOUT for capture in a log
    def print_stats
      @end_time = Time.new
      @elapsed_time = @end_time - @start_time
      puts "Total time: " + @elapsed_time.to_s + "\n"
      puts "Completed objects: " + self.success_count.to_s + "\n"
      puts "Errors: " + self.error_count.to_s + "\n"    
    end

  end
end