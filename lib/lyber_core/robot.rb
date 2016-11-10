require 'benchmark'
require 'active_support/core_ext/string/inflections' # camelcase

module LyberCore
  module Robot

    # Add the ClassMethods to the class this is being mixed into
    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods

      # Called by job-manager on derived-class
      # Instantiate the Robot and call #work with the passed in druid
      def perform(druid)
        # Get the name of the derived-class that was invoked
        klazz = self.name.split('::').inject(Object) {|o,c| o.const_get c}
        bot = klazz.new
        bot.work druid
      end
    end

    
    # Converts a given step to the Robot class name
    # Examples:
    #
    # - `dor:assemblyWF:jp2-create` into `Robots::DorRepo::Assembly::Jp2Create`
    # - `dor:gisAssemblyWF:start-assembly-workflow` into `Robots::DorRepo::GisAssembly::StartAssemblyWorkflow`
    # - `dor:etdSubmitWF:binder-transfer` into `Robots:DorRepo::EtdSubmit::BinderTransfer`
    #
    # @param [String] step. fully qualified step name, e.g., `dor:accessionWF:descriptive-metadata`
    # @param [Hash] opts
    # @option :repo_suffix defaults to `Repo`
    # @return [String] The class name for the robot, e.g., `Robots::DorRepo::Accession:DescriptiveMetadata`
    def self.step_to_classname step, opts = {}
      # generate the robot job class name
      opts[:repo_suffix] ||= 'Repo'
      r, w, s = step.split(/:/, 3)
      return [
        'Robots',
        r.camelcase + opts[:repo_suffix], # 'Dor' conflicts with dor-services
        w.sub('WF', '').camelcase,
        s.gsub('-', '_').camelcase
      ].join('::')
    end

    attr_accessor :check_queued_status
    attr_reader :workflow_service

    def initialize(repo, workflow_name, step_name, opts = {})
      Signal.trap("QUIT") { puts "#{Process.pid} ignoring SIGQUIT" } # SIGQUIT ignored to let the robot finish
      @repo = repo
      @workflow_name = workflow_name
      @step_name = step_name
      @check_queued_status = opts.fetch(:check_queued_status, true)
      @workflow_service = opts.fetch(:workflow_service, Dor::WorkflowService)
    end

    # Sets up logging, timing and error handling of the job
    # Calls the #perform method, then sets workflow to 'completed' or 'error' depending on success
    def work(druid)
      LyberCore::Log.set_logfile($stdout)                     # let process manager(bluepill) handle logging
      LyberCore::Log.info "#{druid} processing"
      return if @check_queued_status && !item_queued?(druid)

      result = nil
      elapsed = Benchmark.realtime do
        result = self.perform druid                                    # implemented in the mixed-in robot class
      end

      # this is the default note to pass back to workflow service, but it can be overriden by a robot that uses the Lybercore::Robot::ReturnState object to return a status
      note = Socket.gethostname
      
      # the final workflow state is determined by the return value of the perform step, if it is a ReturnState object, 
      # we will use the defined status, otherwise default to completed
      # if a note is passed back, we will also use that instead of the default
      if result.class == LyberCore::Robot::ReturnState
        workflow_state = result.status
        note = result.note unless result.note.blank?
      else
        workflow_state = 'completed'  
      end
      
      # update the workflow status from 'queued' to the state returned by perform (or 'completed' as the default) 
      # NOTE errors out if current status is not queued
      workflow_service.update_workflow_status @repo, druid, @workflow_name, @step_name, workflow_state, :elapsed => elapsed, :note => note, :current_status => 'queued'
      LyberCore::Log.info "Finished #{druid} in #{sprintf("%0.4f",elapsed)}s"

    rescue => e
      begin
        LyberCore::Log.error e.message + "\n" + e.backtrace.join("\n")
        workflow_service.update_workflow_error_status @repo, druid , @workflow_name, @step_name, e.message, :error_text => Socket.gethostname
      rescue => e2
        LyberCore::Log.error "Cannot set #{druid} to status='error'\n" + e2.message + "\n" + e2.backtrace.join("\n")
        raise e2 # send exception to Resque failed queue
      end
    end

    private

    def item_queued?(druid)
      status = workflow_service.get_workflow_status(@repo, druid, @workflow_name, @step_name)
      if(status =~ /queued/i)
        return true
      else
        LyberCore::Log.warn "Item is not queued, but has status of '#{status}'. Will skip processing"
        return false
      end
    end

  end
end
