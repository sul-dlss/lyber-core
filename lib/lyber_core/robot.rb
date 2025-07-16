# frozen_string_literal: true

module LyberCore
  # Base class for all robots.
  # Subclasses should implement the #perform_work method.
  # To enable retries provide the retriable exceptions in the initializer.
  class Robot
    include Sidekiq::Job
    # Setting sidekiq_options here won't work.
    # Instead pass options when enqueueing the job with Sidekiq::Client.push. (Currently in Workflow's QueueService.)

    sidekiq_options log_level: :debug

    sidekiq_retries_exhausted do |job, ex|
      # When all the retries are exhausted, update the workflow to error.
      robot = job['class'].constantize.new
      druid = job['args'].first
      workflow = Workflow.new(object_client: Dor::Services::Client.object(druid),
                              workflow_name: robot.workflow_name,
                              process: robot.process,
                              logger: Sidekiq.logger)
      workflow.error!(ex.message, Socket.gethostname)
    end

    attr_reader :workflow_name, :process, :druid, :retriable_exceptions
    attr_accessor :check_queued_status

    # These methods are delegated to the workflow ivar as a convenient way for child classes to interact
    # with the workflow service (to e.g. to create workflows, update status, set error status, etc). See
    # dor-services-client readme and code (or robot subclass implementations) for suggestions on specific
    # usages.
    delegate :lane_id, :object_workflow, :workflow_process, :workflow_response, :process_response, to: :workflow

    def initialize(workflow_name, process, check_queued_status: true, retriable_exceptions: [])
      @workflow_name = workflow_name
      @process = process
      @check_queued_status = check_queued_status
      @retriable_exceptions = retriable_exceptions
    end

    def object_client
      logger.info("JM_LOG: #{__method__} called from #{caller.first}: @object_client: #{@object_client} ")
      @object_client ||= Dor::Services::Client.object(druid).tap do |dsco|
        logger.info("JM_LOG: #{__method__} called from #{caller.first}: @object_client set to: #{dsco}")
      end
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
      Honeybadger.context(druid:, process:, workflow_name:)

      logger.info "#{druid} processing #{process} (#{workflow_name})"
      return unless check_item_queued_or_retry?

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
    rescue *retriable_exceptions => e
      handle_error(e)
      workflow.retrying!
      raise
    rescue StandardError => e
      handle_error(e)
      workflow.error!(e.message, Socket.gethostname)
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

    def handle_error(error)
      Honeybadger.notify(error)
      logger.error "#{error.message}\n#{error.backtrace.join("\n")}"
    end

    def workflow
      Workflow.new(object_client:, workflow_name:, process:, logger:)
    end

    def check_item_queued_or_retry?
      return true unless check_queued_status

      return true if /queued/i.match?(workflow.status)
      return true if /retrying/i.match?(workflow.status)

      msg = "Item #{druid} is not queued for #{process} (#{workflow_name}), " \
            "but has status of '#{workflow.status}'. Will skip processing"
      Honeybadger.notify(msg)
      logger.warn(msg)
      false
    end
  end
end
