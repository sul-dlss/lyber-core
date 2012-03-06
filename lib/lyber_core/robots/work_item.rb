# require 'dor_service'
require "xml_models/identity_metadata/identity_metadata"
require "xml_models/identity_metadata/dublin_core"


# Represents a single object being processed as part of a workflow queue
module LyberCore
  module Robots
    class WorkItem

      # The queue that this workitem is a member of
      attr_reader :work_queue
      # The primary id for the object being processed
      attr_accessor :druid
      # The object's identifiers
      attr_reader :identifiers
      # Timings for this workitem's processing
      attr_reader :start_time
      attr_reader :end_time
      attr_reader :elapsed_time

      # Create a new WorkItem object, save a pointer to the parent WorkQueue, and start the timer
      def initialize(work_queue)
        @work_queue = work_queue
        @start_time = Time.new
        @identifiers = Hash.new { |h,k| h[k] = [] }
      end

      # Return the identifier value for the specified identier name
      def identifier(key)
        return @identifiers[key]
      end

      # Add a new name,value pair to the set of identifiers
      def identifier_add(key, value)
        @identifiers[key] << value
      end

      # Return an array of strings where each entry consists of name:value
      def id_pairs
        @identifiers.collect { |k,vs| vs.collect { |v| "#{k}:#{v}" } }.flatten
      end

      # Return the druid for the work item if it exists, else the first identifier value
      def item_id
        return @druid if @druid
        return id_pairs[0]
      end

      # Record a non-error status for the workstep operation
      def set_status(status)
        @elapsed_time = Time.new - @start_time
        @end_time = Time.new
        @elapsed_time = @end_time - @start_time
        LyberCore::Log.info("#{item_id} #{status} in #{@elapsed_time} seconds")
        if (@druid)
          Dor::WorkflowService.update_workflow_status(@work_queue.workflow.repository, @druid, @work_queue.workflow.workflow_id, @work_queue.workflow_step, status, @elapsed_time)
        end
      end

      # Record the successful outcome of the workstep operation for this workitem
      def set_success
        @work_queue.success_count += 1
        self.set_status('completed')
      end

      # Record the unsuccessful outcome of the workstep operation for this workitem
      def set_error(e)
        @work_queue.error_count += 1
        @end_time = Time.new
        @elapsed_time = @end_time - @start_time
        if (e.is_a?(LyberCore::Exceptions::ItemError) )
          item_error = e
        else
          item_error = LyberCore::Exceptions::ItemError.new(@druid, "Item error", e)
        end
        LyberCore::Log.exception(item_error)
        if (@druid)
          Dor::WorkflowService.update_workflow_error_status(@work_queue.workflow.repository, @druid, @work_queue.workflow.workflow_id, @work_queue.workflow_step, item_error.message)
        end
      end
      
    end
  end
end