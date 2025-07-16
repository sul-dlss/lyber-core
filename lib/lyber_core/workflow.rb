# frozen_string_literal: true

module LyberCore
  # This encapsulates the workflow operations that lyber-core does
  class Workflow
    def initialize(object_client:, workflow_name:, process:, logger: Sidekiq.logger)
      @object_client = object_client
      @workflow_name = workflow_name
      @process = process
      @logger = logger
    end

    def object_workflow
      object_client.workflow(workflow_name).tap do |ocw|
        logger.info("JM_LOG #{__method__} called from #{caller.first}: object_workflow: #{ocw}")
      end
    end

    def workflow_process
      object_workflow.process(process)
    end

    def workflow_response
      object_workflow.find
    end

    def process_response
      workflow_response.process_for_recent_version(name: process)
    end

    def start!(note)
      workflow_process.update(status: 'started', elapsed: 1.0, note:)
    end

    def complete!(status, elapsed, note)
      workflow_process.update(status:, elapsed:, note:)
    end

    def retrying!
      workflow_process.update(status: 'retrying', elapsed: 1.0, note: nil)
    end

    def error!(error_msg, error_text)
      workflow_process.update_error(error_msg:, error_text:)
    end

    # @return [Hash] any workflow context associated with the workflow
    def context
      process_response.context
    end

    def status
      workflow_process.status
    end

    def lane_id
      process_response.lane_id
    end

    attr_reader :object_client, :workflow_name, :process, :logger
  end
end
