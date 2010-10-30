require 'dor_service'
require "roxml_models/identity_metadata/identity_metadata"
require "roxml_models/identity_metadata/dublin_core"

# Represents a single object being processed as part of a workflow queue
module LyberCore
  module Robots
    class WorkItem

      # The queue that this workitem is a member of
      attr_reader :work_queue
      # The primary id for the object being processed
      attr_accessor :druid
      # An object used to hold unmarshalled XML from the identityMetadata datastream
      attr_accessor :identity_metadata
      # Timings for this workitem's processing
      attr_reader :start_time
      attr_reader :end_time
      attr_reader :elapsed_time

      # Create a new WorkItem object, save a pointer to the parent WorkQueue, and start the timer
      def initialize(work_queue)
        @work_queue = work_queue
        @start_time = Time.new
      end

      # Inject an IdentityMetadata object (currently used for unit testing only)
      def identity_metadata=(identity_metadata)
        @identity_metadata = identity_metadata
      end
    
      #save the IdentityMetadata object to identityMetadata datastream
      def identity_metadata_save
        unless DorService.get_datastream(@druid, 'identityMetadata')
          DorService.add_datastream(@druid, 'identityMetadata', 'identityMetadata', self.identity_metadata.to_xml.to_xml)
        else
          DorService.update_datastream(@druid, 'identityMetadata', self.identity_metadata.to_xml.to_xml, content_type='application/xml', versionable = false)
        end #unless
      end #identity_metadata_save

      # Return the IdentityMetadata object bound to identityMetadata datastream XML
      def identity_metadata
        if (@identity_metadata == nil)
          if (@druid == nil)
            @identity_metadata = IdentityMetadata.new
          else
            idmd_str = DorService.get_datastream(@druid, 'identityMetadata')
            @identity_metadata = IdentityMetadata.from_xml(idmd_str)
          end
        end
        return @identity_metadata
      end

      # Return the identifier value for the specified identier name
      def identifier(key)
        return self.identity_metadata.get_identifier_value(key)
      end

      # Add a new name,value pair to the set of identifiers
      def identifier_add(key, value)
        self.identity_metadata.add_identifier(key, value)
      end

      # Return an array of strings where each entry consists of name:value
      def id_pairs
        self.identity_metadata.get_id_pairs
      end

      # Return the druid for the work item if it exists, else the first identifier value
      def item_id
        return @druid if @druid
        pairs = self.identity_metadata.get_id_pairs
        return pairs[0] if (pairs.size > 0)
      end

      # Record the successful outcome of the workstep operation for this workitem
      def set_success
        @work_queue.success_count += 1
        @end_time = Time.new
        @elapsed_time = @end_time - @start_time
        LyberCore::Log.info("#{item_id} completed in #{@elapsed_time} seconds")
        if (@druid)
          Dor::WorkflowService.update_workflow_status(@work_queue.workflow.repository, @druid, @work_queue.workflow.workflow_id, @work_queue.workflow_step, 'completed', @elapsed_time)
        end
      end

      # Record the unsuccessful outcome of the workstep operation for this workitem
      def set_error(e)
        @work_queue.error_count += 1
        @end_time = Time.new
        @elapsed_time = @end_time - @start_time
        LyberCore::Log.error("#{item_id} error - #{e.backtrace}")
        # By default puts will output an array with a newline between each item.
        if (@druid)
          DorService.update_workflow_error_status(@work_queue.workflow.repository, @druid, @work_queue.workflow.workflow_id, @work_queue.workflow_step, e.message)
        end
        # We've caught and processed the error at this point, I don't think we want to raise it again. --bess
        # raise e
      end

    end
  end
end