module LyberCore
  module Robot

    # Add the ClassMethods to the class this is being mixed into
    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      # Called by Resque on derived-class
      # Instantiate the Robot and call #work with the passed in druid
      def perform(druid)
        # Get the name of the derived-class that was invoked
        klazz = self.name.split('::').inject(Object) {|o,c| o.const_get c}
        bot = klazz.new
        bot.work druid
      end
    end

    def initialize(repo, workflow_name, step_name, opts = {})
      @repo = repo
      @workflow_name = workflow_name
      @step_name = step_name
      # create option to check return value of process_item
      # @check_if_processed = opts.fetch(:check_if_processed, false)
    end

    # Sets up logging, timing and error handling of the job
    # Calls the #perform method, then sets workflow to 'completed' or 'error' depending on success
    def work(druid)
      LyberCore::Log.set_logfile($stdout)                     # let process manager(bluepill) handle logging
      # TODO check workflow status of item, output warning if item is not 'queued'
      LyberCore::Log.info "Processing #{@druid}"
      start = Time.now
      self.perform druid                                      # implemented in the mixed in robot class
      # TODO check return value of #process_item if @check_if_processed == true ( have a self.processed? method that gets set in #process_item)
      #   if true returned, update step to completed
      #   otherwise, the robot did something like set the step to 'waiting' with a note
      elapsed = Time.now - start
      Dor::WorkflowService.update_workflow_status @repo, druid, @workflow_name, @step_name, 'completed', :elapsed => elapsed
      LyberCore::Log.info "Finished #{druid} in #{elapsed}s"  # or use some other profiling/timing
    rescue => e
      LyberCore::Log.error e.message + "\n" + e.backtrace.join("\n")
      Dor::WorkflowService.update_workflow_error_status @repo, druid , @workflow_name, @step_name, e.message
      raise  # or just swallow the error?  need a tab in UI to handle failed queue in more detail
    end

  end
end
