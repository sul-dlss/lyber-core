# frozen_string_literal: true

require 'benchmark'

module LyberCore
  module Robot
    # Add the ClassMethods to the class this is being mixed into
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Called by job-manager on derived-class
      # Instantiate the Robot and call #work with the passed in druid
      def perform(druid)
        bot = new
        bot.work druid
      end
    end

    attr_accessor :check_queued_status
    attr_reader :workflow_service, :workflow_name, :process

    def initialize(workflow_name, process, workflow_service:, check_queued_status: true)
      Signal.trap('QUIT') { puts "#{Process.pid} ignoring SIGQUIT" } # SIGQUIT ignored to let the robot finish
      @workflow_name = workflow_name
      @process = process
      @check_queued_status = check_queued_status
      @workflow_service = workflow_service
    end

    # Sets up logging, timing and error handling of the job
    # Calls the #perform method, then sets workflow to 'completed' or 'error' depending on success
    def work(druid)
      Honeybadger.context(druid: druid, process: process, workflow_name: workflow_name) if defined? Honeybadger

      LyberCore::Log.set_logfile($stdout) # let process manager(bluepill) handle logging
      LyberCore::Log.info "#{druid} processing"
      return if check_queued_status && !item_queued?(druid)

      # this is the default note to pass back to workflow service,
      # but it can be overriden by a robot that uses the Lybercore::Robot::ReturnState
      # object to return a status
      note = Socket.gethostname

      # update the workflow status to indicate that started
      workflow_service.update_status(druid: druid,
                                     workflow: workflow_name,
                                     process: process,
                                     status: 'started',
                                     elapsed: 1.0,
                                     note: note)

      result = nil
      elapsed = Benchmark.realtime do
        result = perform druid # implemented in the mixed-in robot class
      end

      # the final workflow state is determined by the return value of the perform step, if it is a ReturnState object,
      # we will use the defined status, otherwise default to completed
      # if a note is passed back, we will also use that instead of the default
      if result.class == LyberCore::Robot::ReturnState
        workflow_state = result.status
        note = result.note unless result.note.blank?
      else
        workflow_state = 'completed'
      end
      # update the workflow status from its current state to the state returned by perform (or 'completed' as the default)
      workflow_service.update_status(druid: druid,
                                     workflow: workflow_name,
                                     process: process,
                                     status: workflow_state,
                                     elapsed: elapsed,
                                     note: note)
      LyberCore::Log.info "Finished #{druid} in #{sprintf('%0.4f', elapsed)}s"
    rescue StandardError => e
      Honeybadger.notify(e) if defined? Honeybadger
      begin
        LyberCore::Log.error e.message + "\n" + e.backtrace.join("\n")
        workflow_service.update_error_status(druid: druid,
                                             workflow: workflow_name,
                                             process: process,
                                             error_msg: e.message,
                                             error_text: Socket.gethostname)
      rescue StandardError => e
        LyberCore::Log.error "Cannot set #{druid} to status='error'\n#{e.message}\n#{e.backtrace.join("\n")}"
        raise e # send exception to Resque failed queue
      end
    end

  private

    def item_queued?(druid)
      status = workflow_service.workflow_status(druid: druid,
                                                workflow: workflow_name,
                                                process: process)
      return true if status =~ /queued/i
      msg = "Item #{druid} is not queued for #{process} (#{workflow_name}), but has status of '#{status}'. Will skip processing"
      Honeybadger.notify(msg) if defined? Honeybadger
      LyberCore::Log.warn msg
      false
    end
  end
end
