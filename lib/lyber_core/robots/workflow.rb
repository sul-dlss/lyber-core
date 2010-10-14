require 'logger'

module LyberCore
  module Robots
    class Workflow

      attr_reader :workflow_name
      attr_reader :collection_name

      attr_reader :workflow_config_dir
      attr_reader :collection_config_dir
      attr_reader :workflow_config
      # This logger object is created by a robot and passed to the workflow object
      attr_reader :logger 

      # The +new+ class method initializes the class.
      # === Parameters
      # * _workflow_name_ = hopefully self-explanatory
      # === Options
      # * _:collection_name_ = the name of a collection to process
      # === Example
      #   @wf = LyberCore::Robots::Workflow.new(wf_name, {:logger => logger, :collection_name => collection})
      def initialize(workflow_name, options = {})
        # ROBOT_ROOT must be set before invoking a robot
        raise "ROBOT_ROOT isn't set. Please set it to point to where your config files live." unless defined? ROBOT_ROOT
        
        @workflow_name = workflow_name
        
        # Most of the time we should receive an existing Logger object from 
        # the robot, but if we don't receive one, make a new one.
        @logger = options[:logger] ? options[:logger] : Logger.new("/tmp/workflow.log")
                
        @collection_name = options[:collection_name]

        # can override the default location of workflow config files
        # by setting WORKFLOW_CONFIG_HOME environmental variable
        unless ROBOT_ROOT        
          if not (config_home = ENV['WORKFLOW_CONFIG_HOME'] )
            config_home = File.join(File.dirname(__FILE__), "..", "..", "config")
          end
        else
          config_home = File.join(ROBOT_ROOT, "config", "workflows")
        end
        
        @workflow_config_dir = File.join(config_home, @workflow_name )
        @logger.debug("@workflow_config_dir = #{@workflow_config_dir}")
        @collection_config_dir = File.join(@workflow_config_dir, @collection_name ) if(@collection_name)
        workflow_config_file = File.join(@workflow_config_dir, 'workflow-config.yaml')
        if (File.exist?(workflow_config_file))
          @workflow_config = YAML.load_file(workflow_config_file)
        else
          raise "Workflow config not found!
          ROBOT_ROOT = #{ROBOT_ROOT}
          expecting to find workflow_config_file in #{workflow_config_file}
          "
        end
      end

      def workflow_collection
        return @workflow_name + "_" + @collection_name
      end

      def workflow_id
        return @workflow_name
      end
    
      # Which repository are we operating against? 
      # Should return either "dor" or "sdr"
      def repository
        return @workflow_config['repository']
      end
      
      # Construct the fully qualified filename and see if
      # a file exists there. If it doesn't exist or isn't
      # a file, raise an error. 
      def workflow_process_xml_filename
        file = File.join(@workflow_config_dir, @workflow_name + '.xml')
        if File.file? file
          return file
        else
          raise "#{file} is not a file"
        end
      end

      # Return the contents of the file at workflow_process_xml_filename
      def workflow_process_xml
        return IO.read(workflow_process_xml_filename)
      end

      def object_template_filepath
        Dir.foreach(@collection_config_dir) do |file| 
          if file.match(/ObjectTemplate.xml$/)
            return File.join(@collection_config_dir, file)
          end
        end
        Dir.foreach(@workflow_config_dir) do |file| 
          if file.match(/ObjectTemplate.xml$/)
            return File.join(@workflow_config_dir, file)
          end
        end
        raise "Object Template not found"
      end
      
      # receives a workflow step and returns 
      def queue(workflow_step)
        return WorkQueue.new(self, workflow_step)
      end
    end
  end
end
