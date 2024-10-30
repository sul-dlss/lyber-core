# frozen_string_literal: true

module LyberCore
  # This encapsulates the workflow operations that lyber-core does
  class Workflow
    def initialize(workflow_service:, druid:, workflow_name:, process:)
      @workflow_service = workflow_service
      @druid = druid
      @workflow_name = workflow_name
      @process = process
    end

    def start!(note)
      workflow_service.update_status(druid:,
                                     workflow: workflow_name,
                                     process:,
                                     status: 'started',
                                     elapsed: 1.0,
                                     note:)
    end

    def complete!(status, elapsed, note)
      workflow_service.update_status(druid:,
                                     workflow: workflow_name,
                                     process:,
                                     status:,
                                     elapsed:,
                                     note:)
    end

    def retrying!
      workflow_service.update_status(druid:,
                                     workflow: workflow_name,
                                     process:,
                                     status: 'retrying',
                                     elapsed: 1.0,
                                     note: nil)
    end

    def error!(error_msg, error_text)
      workflow_service.update_error_status(druid:,
                                           workflow: workflow_name,
                                           process:,
                                           error_msg:,
                                           error_text:)
    end

    # @return [Hash] any workflow context associated with the workflow
    def context
      @context ||= workflow_service.process(pid: druid,
                                            workflow_name:,
                                            process:).context
    end

    def status
      @status ||= workflow_service.workflow_status(druid:,
                                                   workflow: workflow_name,
                                                   process:)
    end

    def lane_id
      @lane_id ||= workflow_service.process(pid: druid, workflow_name:, process:).lane_id
    end

    private

    attr_reader :workflow_service, :druid, :workflow_name, :process
  end
end
