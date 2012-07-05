
module LyberCore
  
  module Robots
    
    # Parses the arguments from the run_robot script, and either starts the ServiceController
    #   in daemon mode, or runs the robot once (to either operate on a druid or a list of druids).
    # @see ServiceController
    class Runner
      
      def initialize(sleep_time = nil)
        @sleep_time = sleep_time
      end
      
      def run
        action = ARGV.shift
        robots = []
        while ARGV.first =~ /:/
          (wf,robot) = ARGV.shift.split(/:/)
          if robot =~ /\*/
            wf_module = Module.const_get(wf.classify[0..-3])
            all_robots = wf_module.constants.select { |c| wf_module.const_get(c).ancestors.include?(LyberCore::Robots::Robot) }
            robot_names = all_robots.collect { |c| c.underscore.dasherize }.select { |c| File.fnmatch?(robot,c) }
            robot_names.each { |r| robots << [wf,r] }
          else
            robots << [wf,robot]
          end
        end

        if action == 'run'
          robots.each do |robot|
            (workflow,robot_name) = robot
            raw_module_name = workflow.split('WF').first
            module_name = raw_module_name[0].chr.upcase << raw_module_name.slice(1, raw_module_name.size - 1)
            robot_klass = Module.const_get(module_name).const_get(robot_name.split(/-/).collect { |w| w.capitalize }.join(''))
            instance = robot_klass.new(:argv => ARGV)
            instance.start
          end
        else
          controller = LyberCore::Robots::ServiceController.new(
            :sleep_time  => @sleep_time,
            :logger      => logger, 
            :working_dir => ROBOT_ROOT, 
            :argv        => ARGV.dup)

          case action
          when 'start'
            robots.each { |robot| controller.start(*robot) }
          when 'stop'
            robots.each { |robot| controller.stop(*robot) }
          when 'status'
            robots.each { |robot| puts controller.status_message(*robot) }
          end
        end  
      end
      
    end
  end
end