require 'benchmark'
require 'active_support'

module LyberCore
  # The skeleton of robots, a replacement for LyberCore::Robot
  # @example To migrate from LyberCore::Robot, replace
  #   class MyRobot
  #     include LyberCore::Robot
  #     def initialize
  #       new(REPOSITORY, WORKFLOW_NAME, ROBOT_NAME)
  #     end
  #     def perform ...
  #   end
  # @example Usage: implement self.worker and override #perform, as before
  #   class MyRobot < LyberCore::Base
  #     def self.worker
  #       new('sdr', 'preservationIngestWF', 'ingest-poison')
  #     end
  #     def perform ...
  #   end
  class Base
    # Called by job-manager: instantiate the Robot and call #work with the druid
    # @param [String] druid
    # @note Override the instance method #perform, probably not this one
    def self.perform(druid)
      worker.work(druid)
    end

    # get an instance, without knowing the params for .new()
    # @return [LyberCore::Base]
    def self.worker
      raise NotImplementedError, 'Implement class method self.worker on the subclass'
    end

    attr_accessor :repo, :workflow_name, :step_name, :check_queued_status, :workflow_service

    def initialize(repo, workflow_name, step_name, opts = {})
      Signal.trap('QUIT') { puts "#{Process.pid} ignoring SIGQUIT" } # SIGQUIT ignored to let the robot finish
      @repo = repo
      @workflow_name = workflow_name
      @step_name = step_name
      @check_queued_status = opts.fetch(:check_queued_status, true)
      @workflow_service = opts.fetch(:workflow_service, Dor::WorkflowService)
    end

    # @return [Logger]
    def logger
      unless @log_init # one time
        LyberCore::Log.set_logfile($stdout) # let process manager(bluepill) handle logging
        @log_init = true
      end
      LyberCore::Log
    end

    # Sets up logging, timing and error handling of the job
    # Calls the #perform method, then sets workflow to 'completed' or 'error' depending on success
    def work(druid)
      logger.info "#{druid} processing"
      return if check_queued_status && !item_queued?(druid)
      result = nil
      elapsed = Benchmark.realtime { result = perform(druid) }
      if result.is_a?(LyberCore::Robot::ReturnState)
        workflow_state = result.status
        note = result.note unless result.note.blank?
      else
        workflow_state = 'completed' # default
      end
      note ||= Socket.gethostname # default
      workflow_service.update_workflow_status(repo, druid, workflow_name, step_name, workflow_state, elapsed: elapsed, note: note)
      logger.info "Finished #{druid} in #{format('%0.4f', elapsed)}s"
    rescue StandardError => e
      Honeybadger.notify(e) if defined? Honeybadger
      begin
        logger.error e.message + "\n" + e.backtrace.join("\n")
        workflow_service.update_workflow_error_status(repo, druid, workflow_name, step_name, e.message, error_text: Socket.gethostname)
      rescue StandardError => e2
        logger.error "Cannot set #{druid} to status='error'\n" + e2.message + "\n" + e2.backtrace.join("\n")
        raise e2 # send exception to Resque failed queue
      end
    end

  private

    def item_queued?(druid)
      status = workflow_service.get_workflow_status(repo, druid, workflow_name, step_name)
      return true if status =~ /queued/i
      logger.warn "Item is not queued, but has status of '#{status}'. Will skip processing"
      false
    end
  end
end
