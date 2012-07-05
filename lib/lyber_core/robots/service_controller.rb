require 'daemons'
require 'logger'
require 'fileutils'

module LyberCore
  module Robots
    class ServiceController < Daemons::ApplicationGroup
      attr_reader :logger
      
      def initialize(opts = {})
        if opts[:logger]
          @logger = opts[:logger]
        else
          @logger = Logger.new($stdout)
          @logger.level = opts[:log_level] || Logger::WARN
        end
        @sleep_time = opts[:sleep_time] || (15*60)
        @working_dir = opts[:working_dir] || ENV['ROBOT_ROOT'] || Dir.pwd
        @pid_dir = opts[:pid_dir] || File.join(@working_dir, 'pid')
        @pid_dir = File.expand_path(@pid_dir)
        FileUtils.mkdir(@pid_dir) unless(File.directory? @pid_dir)
        @argv = (opts[:argv] || []).dup
        @logger.debug "Initializing application group."
        @logger.debug "Writing pids to #{@pid_dir}"
        @max_robot_retries = opts[:max_robot_retries] || 5
        super('robot_service_controller', :dir_mode => :normal, :dir => @pid_dir, :multiple => true, :backtrace => true)
      end

      def qname(workflow, robot_name)
        [workflow,robot_name].join(':')
      end
      
      def start(workflow, robot_name)
        result = false
        app = find_app(workflow, robot_name).first
        process_name = qname(workflow,robot_name)
        if app.nil? or (app.running? == false)
          @logger.info "Starting #{process_name}..."
          with_app_name("#{process_name}") do
            app, message = capture_stdout do
              raw_module_name = workflow.split('WF').first
              module_name = raw_module_name[0].chr.upcase << raw_module_name.slice(1, raw_module_name.size - 1)
              robot_klass = Module.const_get(module_name).const_get(robot_name.split(/-/).collect { |w| w.capitalize }.join(''))
              @files_to_reopen = ObjectSpace.each_object(File).select { |f| not f.closed? }
              robot_proc = lambda { robot_proc_loop(robot_klass, process_name) }
              new_app = self.new_application({:mode => :proc, :proc => robot_proc, :dir_mode => :normal, :log_output => true, :log_dir => @pid_dir})
              new_app.start
              new_app
            end
          end
          
          if app.running?
            @logger.info "#{process_name} [#{app.pid.pid}] started."
            result = true
          else
            @logger.error "Unable to start #{process_name}"
          end
        else app.running?
          @logger.warn "Robot #{process_name} [#{app.pid.pid}] is already running"
        end
        return result
      end
      
      # Starts the robot in a loop.  It will sleep when the robot finishies normally, or break out of the loop if the robot halts from too many errors.
      # If starting the robot throws an exception, it will sleep and try again @sleep_time seconds later.  
      # If it fails to start after @max_robot_retries attempts, it will shut down completely.
      # @param [String] robot_klass class of the robot to be instantiated
      # @param [String] process_name name of the robot process, usually workflow_name:robot_name
      def robot_proc_loop(robot_klass, process_name)
        Dir.chdir(@working_dir) do
          begin
            @files_to_reopen.each { |f| f.reopen(f.path).sync = true rescue true }
            robot = robot_klass.new(:argv => @argv.dup)
            @attempts = 1
            loop {
              begin 
                case robot.start 
                when LyberCore::Robots::SLEEP
                  @logger.info "SLEEP condition reached in #{process_name}. Sleeping for #{@sleep_time} seconds."
                  @attempts = 1
                  sleep(@sleep_time)
                when LyberCore::Robots::HALT
                  @logger.error "HALT condition reached in #{process_name}. Shutting down."
                  break
                end
              rescue SystemExit => se
                 @logger.info("SystemExit received.")
                 raise se
              rescue Exception => e
                # Problem starting the robot, usually workflow related
                @logger.warn "Exception thrown trying to start #{process_name}:\n#{e.inspect}\n#{e.backtrace.join("\n")}"
                
                if(@attempts < @max_robot_retries)
                  @attempts += 1
                  @logger.warn "Will try #{process_name} start attempt# #{@attempts} in #{@sleep_time} seconds"
                  sleep(@sleep_time)
                else
                  @logger.error "!!!!!!!! #{@attempts} failed attempts trying to start #{process_name} !!!!!!!!!!!!"
                  break
                end
              end
            }
          ensure
            @logger.info "Shutting down."
          end
        end
        
      end

      def stop(workflow, robot_name)
        apps = find_app(workflow, robot_name)
        process_name = qname(workflow,robot_name)
        result = false
        if apps.empty?
          @logger.info "Robot #{process_name} not found"
        else
          apps.each do |app|
            if app.running?
              @logger.info "Shutting down #{process_name} [#{app.pid.pid}]..."
              result, message = capture_stdout { app.stop }
              if app.running?
                @logger.error "Unable to stop #{process_name} [#{app.pid.pid}]."
              else
                @logger.info "#{process_name} [#{app.pid.pid}] shut down."
                result = true
              end
            else
              @logger.warn "Robot #{process_name} [#{app.pid.pid}] is not running but pidfile exists"
              app.zap!
            end
          end
        end
        result
      end
  
      def status(workflow, robot_name)
        apps = find_app(workflow, robot_name)
        apps.collect do |app|
          { :pid => app.pid.pid, :status => app.running? ? :running : :stopped }
        end
      end
  
      def status_message(workflow, robot_name)
        app_status = status(workflow, robot_name)
        process_name = qname(workflow,robot_name)
        if app_status.empty?
          ["Robot #{process_name} not found"]
        else
          app_status.collect do |s|
            case s[:status]
            when :running
              "Robot #{process_name} [#{s[:pid]}] is running"
            when :stopped
              "Robot #{process_name} [#{s[:pid]}] is not running but pidfile exists"
            end
          end
        end
      end
  
#      private
      def with_app_name(name)
        old_name, @app_name = @app_name, name
        begin
          return yield
        ensure
          @app_name = old_name
        end
      end
      
      def capture_stdout
        old_io = $stdout
        begin
          new_io = StringIO.new('')
          $stdout = new_io
          result = yield
          @logger.debug new_io.string
          return result, new_io.string
        ensure
          $stdout = old_io
        end
      end
  
      def find_app(workflow, robot_name)
        with_app_name(qname(workflow,robot_name)) {
          self.find_applications_by_pidfiles(@pid_dir)
        }
      end
    end
  end
end