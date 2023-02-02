# frozen_string_literal: true

module LyberCore
  # Base class for all robots.
  # Subclasses should implement the #perform_work method.
  class Robot
    include Sidekiq::Job
    sidekiq_options retry: 0

    attr_reader :workflow_name, :process, :druid

    delegate :lane_id, to: :workflow

    def initialize(workflow_name, process)
      @workflow_name = workflow_name
      @process = process
    end

    def workflow_service
      @workflow_service ||= WorkflowClientFactory.build(logger: logger)
    end

    def object_client
      @object_client ||= Dor::Services::Client.object(druid)
    end

    def cocina_object
      @cocina_object ||= object_client.find
    end

    def druid_object
      @druid_object ||= DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
    end

    # Sets up logging, timing and error handling of the job
    # Calls the #perform_work method, then sets workflow to 'completed' or 'error' depending on success
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def perform(druid)
      @druid = druid
      Honeybadger.context(druid: druid, process: process, workflow_name: workflow_name)

      logger.info "#{druid} processing #{process} (#{workflow_name})"
      return unless check_item_queued?

      # this is the default note to pass back to workflow service,
      # but it can be overriden by a robot that uses the Robots::ReturnState
      # object to return a status
      note = Socket.gethostname

      # update the workflow status to indicate that started
      workflow.start!(note)

      result = nil
      elapsed = Benchmark.realtime do
        result = perform_work
      end

      # the final workflow state is determined by the return value of the perform step, if it is a ReturnState object,
      # we will use the defined status, otherwise default to completed
      # if a note is passed back, we will also use that instead of the default
      if result.instance_of?(ReturnState)
        workflow_state = result.status
        note = result.note unless result.note.blank?
      else
        workflow_state = 'completed'
      end
      # update the workflow status from its current state to the state returned by perform
      # (or 'completed' as the default)
      # noop allows a robot to not set a workflow as complete, e.g., if that is delegated to another service.
      workflow.complete!(workflow_state, elapsed, note) unless workflow_state == 'noop'

      logger.info "Finished #{druid} in #{format('%0.4f', elapsed)}s"
    rescue StandardError => e
      handle_error(e)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # Work performed by the robot.
    # This method is to be implemented by robot subclasses.
    def perform_work
      raise NotImplementedError
    end

    def bare_druid
      @bare_druid = druid.delete_prefix('druid:')
    end

    private

    # rubocop:disable Metrics/AbcSize
    def handle_error(error)
      Honeybadger.notify(error)
      logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
      workflow.error!(error.message, Socket.gethostname)
    rescue StandardError => e
      logger.error "Cannot set #{druid} to status='error'\n#{e.message}\n#{e.backtrace.join("\n")}"
      raise e # send exception to Sidekiq failed queue
    end
    # rubocop:enable Metrics/AbcSize

    def workflow
      @workflow ||= Workflow.new(workflow_service: workflow_service,
                                 druid: druid,
                                 workflow_name: workflow_name,
                                 process: process)
    end

    def check_item_queued?
      return true if /queued/i.match?(workflow.status)

      msg = "Item #{druid} is not queued for #{process} (#{workflow_name}), " \
            "but has status of '#{workflow.status}'. Will skip processing"
      Honeybadger.notify(msg)
      logger.warn(msg)
      false
    end
  end
end
