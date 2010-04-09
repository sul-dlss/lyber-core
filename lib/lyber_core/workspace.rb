module LyberCore

  class Workspace

    attr_reader :workflow_name
    attr_reader :collection_name
    attr_reader :workspace_base

    def initialize(workflow_name, collection_name=nil)
      @workflow_name = workflow_name
      @collection_name = collection_name

      # can override the default location of workspace files
      # by setting WORKSPACE_HOME environmental variable
      if not (workspace_home = ENV['WORKSPACE_HOME'] )
        workspace_home = WORKSPACE_HOME
      end

      if (@collection_name)
        @workspace_base = File.join(workspace_home, @workflow_name, @collection_name)
      else
        @workspace_base = File.join(workspace_home, @workflow_name)
      end
      FileUtils.mkdir_p(@workspace_base) unless File.directory?(@workspace_base)
    end


    def object_dir(dir_type, druid)
      normalized_druid = druid.sub(/druid:/, '')
      dir_name = File.join(@workspace_base, dir_type, normalized_druid)
      FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)
      return dir_name
    end

    def original_dir(druid)
      return object_dir('original', druid)
    end

    def content_dir(druid)
      return object_dir('content', druid)
    end

    def metadata_dir(druid)
      return object_dir('metadata', druid)
    end

  end

end