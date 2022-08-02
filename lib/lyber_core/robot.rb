# frozen_string_literal: true

require 'benchmark'
require 'socket'
require 'active_support'
require 'active_support/core_ext/object/blank' # String#blank?

module LyberCore
  module Robot
    # Add the ClassMethods to the class this is being mixed into
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Called by job-manager on derived-class
      # Instantiate the Robot and call #work with the passed in druid
      def perform(druid, *context)
        bot = new
        bot.work druid, context
      end
    end

    attr_accessor :check_queued_status
    attr_reader :workflow_name, :process

    def initialize(workflow_name, process, check_queued_status: true)
      Signal.trap('QUIT') { puts "#{Process.pid} ignoring SIGQUIT" } # SIGQUIT ignored to let the robot finish
      @workflow_name = workflow_name
      @process = process
      @check_queued_status = check_queued_status
    end

    def workflow_service
      raise 'The workflow_service method must be implemented on the class that includes LyberCore::Robot'
    end

    # Sets up logging, timing and error handling of the job
    # Calls the #perform method, then sets workflow to 'completed' or 'error' depending on success
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def work(druid, context)
      Honeybadger.context(druid: druid, process: process, workflow_name: workflow_name) if defined? Honeybadger
      workflow = workflow(druid)
      LyberCore::Log.set_logfile($stdout) # let process manager handle logging
      LyberCore::Log.info "#{druid} processing #{process} (#{workflow_name})"
      return if check_queued_status && !item_queued?(druid)

      # this is the default note to pass back to workflow service,
      # but it can be overriden by a robot that uses the Lybercore::Robot::ReturnState
      # object to return a status
      note = Socket.gethostname

      # update the workflow status to indicate that started
      workflow.start(note)

      result = nil
      elapsed = Benchmark.realtime do
        result = if method(:perform).arity == 1
                   perform druid # implemented in the mixed-in robot class
                 else
                   perform druid, context
                 end
      end

      # the final workflow state is determined by the return value of the perform step, if it is a ReturnState object,
      # we will use the defined status, otherwise default to completed
      # if a note is passed back, we will also use that instead of the default
      if result.instance_of?(LyberCore::Robot::ReturnState)
        workflow_state = result.status
        note = result.note unless result.note.blank?
      else
        workflow_state = 'completed'
      end
      # update the workflow status from its current state to the state returned by perform (or 'completed' as the default)
      # noop allows a robot to not set a workflow as complete, e.g., if that is delegated to another service.
      workflow.complete(workflow_state, elapsed, note) unless workflow_state == 'noop'

      LyberCore::Log.info "Finished #{druid} in #{sprintf('%0.4f', elapsed)}s"
    rescue StandardError => e
      Honeybadger.notify(e) if defined? Honeybadger
      begin
        LyberCore::Log.error "#{e.message}\n#{e.backtrace.join("\n")}"
        workflow.error(e.message, Socket.gethostname)
      rescue StandardError => e
        LyberCore::Log.error "Cannot set #{druid} to status='error'\n#{e.message}\n#{e.backtrace.join("\n")}"
        raise e # send exception to Resque failed queue
      end
    end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  private

    def workflow(druid)
      Workflow.new(workflow_service: workflow_service,
                   druid: druid,
                   workflow_name: workflow_name,
                   process: process)
    end

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
