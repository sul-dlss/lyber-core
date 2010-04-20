
module LyberCore
  class Workflow

    attr_reader :workflow_name
    attr_reader :collection_name

    attr_reader :workflow_config_dir
    attr_reader :collection_config_dir
    attr_reader :workflow_config

    def initialize(workflow_name, collection_name=nil)
      @workflow_name = workflow_name
      @collection_name = collection_name

      # can override the default location of workflow config files
      # by setting WORKFLOW_CONFIG_HOME environmental variable        
      if not (config_home = ENV['WORKFLOW_CONFIG_HOME'] )
        config_home = File.join(File.dirname(__FILE__), "..", "..", "config")
      end

      @workflow_config_dir = File.join(config_home, @workflow_name )
      @collection_config_dir = File.join(@workflow_config_dir, @collection_name ) if(@collection_name)
      workflow_config_file = File.join(@workflow_config_dir, 'workflow-config.yaml')
      if (File.exist?(workflow_config_file))
        @workflow_config = YAML.load_file(workflow_config_file)
      end
    end

    def workflow_collection
      return @workflow_name + "_" + @collection_name
    end

    def workflow_id
      return @workflow_name + 'WF'
    end

    def workflow_process_xml
      workflow_process_xml_filename = File.join(@workflow_config_dir, @workflow_name + 'Workflow.xml')
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

    def queue(workflow_step)
      return WorkQueue.new(self, workflow_step)
    end

  end
end