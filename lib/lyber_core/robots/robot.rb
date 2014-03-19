module LyberCore
  module Robots
    class Robot

      # Called by Resque on derived-class
      def self.perform(druid)
        # Get the name of the derived-class that was invoked
        klazz = self.name.split('::').inject(Object) {|o,c| o.const_get c}
        bot = klazz.new(druid)
        bot.perform
      end

      def initialize(repo, workflow_name, step_name, druid, opts = {})
        @repo = repo
        @workflow_name = workflow_name
        @step_name = step_name
        @druid = druid
        # create option to check return value of process_item
        # @check_if_processed = opts.fetch(:check_if_processed, false)
      end

      def perform
        begin
          LyberCore::Log.set_logfile($stdout) # let bluepill/process manger handle logging
          start = Time.now
          LyberCore::Log.info "Processing #{@druid}"
          self.process_item   # implemented in the derived robot class
          # TODO check return value of #process_item if @check_if_processed == true
          #   if true returned, update step to completed
          #   otherwise, the robot did something like set the step to 'waiting' with a note
          elapsed = Time.now - start
          Dor::WorkflowService.update_workflow_status @repo, @druid, @workflow_name, @step_name, 'completed', :elapsed => elapsed
          LyberCore::Log.info "Finished #{@druid} in #{elapsed}s"  # or use some other profiling/timing
        rescue => e
          LyberCore::Log.error e.message + "\n" + e.backtrace.join("\n")
          Dor::WorkflowService.update_workflow_error_status @repo, @druid, @workflow_name, @step_name, e.message + "\n" + e.backtrace.join("\n")
          raise  # or just swallow the error?  need a tab in UI to handle failed queue in more detail
        end
      end

    end
  end
end