module LyberCore
  module Robots
    class Workflow

      attr_reader :workflow_name
      attr_reader :workflow_config_dir
      attr_reader :workflow_config_file
      attr_reader :workflow_config
      
      attr_reader :collection_name
      attr_reader :collection_config_dir
      
      

      # @param [String] workflow_name name of the workflow
      # @param [Hash] options a hash of optional arguments
      # @return [LyberCore::Robots::Workflow] a workflow object
      # @example Create a new workflow object with a collection_name
      #   @wf = LyberCore::Robots::Workflow.new(workflow_name, {:collection_name => collection})
      def initialize(workflow_name, options = {})
        # ROBOT_ROOT must be set before invoking a robot
        raise "ROBOT_ROOT isn't set. Please set it to point to where your config files live." unless defined? ROBOT_ROOT
        
        @workflow_name = workflow_name
        @collection_name = options[:collection_name]
        self.load_workflow_config
      end
      
      def load_workflow_config
        # # can override the default location of workflow config files
        # # by setting WORKFLOW_CONFIG_HOME environmental variable
        unless ROBOT_ROOT        
          if not (config_home = ENV['WORKFLOW_CONFIG_HOME'] )
            config_home = File.join(File.dirname(__FILE__), "..", "..", "config")
          end
        else
          config_home = File.join(ROBOT_ROOT, "config", "workflows")
        end
        
        @workflow_config_dir = File.join(config_home, @workflow_name )
        LyberCore::Log.debug("@workflow_config_dir = #{@workflow_config_dir}")
        @collection_config_dir = File.join(@workflow_config_dir, @collection_name ) if(@collection_name)
        @workflow_config_file = File.join(@workflow_config_dir, 'workflow-config.yaml')
        if (File.exist?(@workflow_config_file))
          @workflow_config = YAML.load_file(workflow_config_file)
        else
          raise "Workflow config not found!
          ROBOT_ROOT = #{ROBOT_ROOT}
          expecting to find workflow_config_file in #{@workflow_config_file}
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
