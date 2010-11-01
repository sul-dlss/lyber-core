require 'dor_service'
require 'dlss_service'
require 'yaml'

module LyberCore
  module Robots
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
      
      attr_reader :config_file


      # Create a new WorkQueue object for the specified step,
      # save a pointer to the parent WorkFlow,
      # start the timer,
      # read in the configuration information for the work step
      def initialize(workflow=nil, workflow_step=nil)
        LyberCore::Log.debug("Initializing work queue with workflow #{workflow} and workflow_step #{workflow_step}")
        @start_time = Time.new
        LyberCore::Log.info("Starting #{workflow_step} at #{@start_time}")
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
        
        self.process_config_file

      end
      
      def process_config_file
          LyberCore::Log.debug("Processing config file ... ")
          LyberCore::Log.debug("@workflow.workflow_config_dir = #{@workflow.workflow_config_dir}")
          
          @config_file = File.join(@workflow.workflow_config_dir, 'process-config.yaml')
          LyberCore::Log.debug("I'm opening the config file at #{@config_file}")
          
          # Does the file exist?
          raise "Can't open process-config file #{@config_file}" unless File.file? @config_file
          
          process_config = YAML.load_file(config_file)
          LyberCore::Log.debug("process_config: #{process_config.inspect}")

          @prerequisite = process_config[@workflow_step]["prerequisite"]
          LyberCore::Log.debug("@prerequisite: #{@prerequisite}")
          
          @batch_limit = process_config[@workflow_step]['batch_limit']  
          LyberCore::Log.debug("@batch_limit: #{@batch_limit}")
          
          @error_limit = process_config[@workflow_step]['error_limit']
          LyberCore::Log.debug("@error_limit: #{@error_limit}")
          
      end

      # Explicitly specify a set of druids to be processed by the workflow step
      def enqueue_druids(druid_array)
        LyberCore::Log.debug("\nEnqueing an array of druids...")
        @druids = druid_array
        LyberCore::Log.debug("\n@druids = #{@druids}")
      end

      # Obtain the set of druids to be processed using a database query
      # to obtain the repository objects that are awaiting this step
      def enqueue_workstep_waiting()
        begin
          LyberCore::Log.debug("\nEnqueing workstep waiting...")
          object_list_xml = DorService.get_objects_for_workstep(workflow.repository, workflow.workflow_id, @prerequisite, @workflow_step)
          LyberCore::Log.debug("\nobject_list_xml = #{object_list_xml}")
          @druids = DlssService.get_some_druids_from_object_list(object_list_xml,self.batch_limit)
          LyberCore::Log.debug("\n@druids = #{@druids}")
        rescue Exception => e
          raise e
        end
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
          LyberCore::Log.info "Batch limit of #{@batch_limit} items reached"
          return nil
        end
        if (@error_count >= @error_limit )
          LyberCore::Log.info "Error limit of #{@error_limit} items reached"
          return nil
        end
        work_item =  LyberCore::Robots::WorkItem.new(self)
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

      # Output the batch's timings and other statistics to the main log file
      def print_stats
        @end_time = Time.new
        @elapsed_time = @end_time - @start_time
        LyberCore::Log.info "Total time: " + @elapsed_time.to_s + "\n"
        LyberCore::Log.info "Completed objects: " + self.success_count.to_s + "\n"
        LyberCore::Log.info "Errors: " + self.error_count.to_s + "\n"    
      end
      
      def print_empty_stats
        @end_time = Time.new
        @elapsed_time = @end_time - @start_time
        LyberCore::Log.info "Total time: " + @elapsed_time.to_s + "\n"
        LyberCore::Log.info "Empty queue"   
      end
    end
  end
end
