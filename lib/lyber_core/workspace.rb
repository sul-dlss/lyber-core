module LyberCore

  class Workspace

    attr_reader :workflow_name
    attr_reader :collection_name

    attr_reader :workspace_base
    attr_reader :workspace_original
    attr_reader :workspace_content
    attr_reader :workspace_metadata

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

      @workspace_original = File.join(@workspace_base, 'original')
      @workspace_content = File.join(@workspace_base, 'content')
      @workspace_metadata = File.join(@workspace_base, 'metadata')
      Dir.mkdir(@workspace_original) unless File.directory?(@workspace_original)
      Dir.mkdir(@workspace_content) unless File.directory?(@workspace_content)
      Dir.mkdir(@workspace_metadata) unless File.directory?(@workspace_metadata)
    end
  end

end
