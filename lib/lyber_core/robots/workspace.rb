require 'fileutils'
module LyberCore
  module Robots
    class Workspace
      
      attr_reader :workflow_name
      attr_reader :collection_name
      attr_reader :workspace_base

      def initialize(workflow_name, collection_name=nil)
        @workflow_name = workflow_name
        @collection_name = collection_name
        @workspace_base = set_workspace_base
        ensure_workspace_exists(@workspace_base)
      end
      
      # Usually WORKSPACE_HOME is set in your environment config file,
      # but you can override the default location of workspace files
      # by setting a WORKSPACE_HOME environment variable
      def set_workspace_home
        begin
          if not (workspace_home = ENV['WORKSPACE_HOME'] )
            workspace_home = Dor::Config.robots.workspace
          end
        rescue NameError => e
          LyberCore::Log.fatal("WORKSPACE_HOME is undefined. Do you need to set it in your config file?")
          raise e
        end
      end
      
      def set_workspace_base
        workspace_home = set_workspace_home
        if (@collection_name)
          @workspace_base = File.join(workspace_home, @workflow_name, @collection_name)
        else
          @workspace_base = File.join(workspace_home, @workflow_name)
        end
      end
      
      def ensure_workspace_exists(workspace)
        begin
          FileUtils.mkdir_p(workspace) unless File.directory?(workspace)
        rescue
          LyberCore::Log.fatal("Can't create workspace_base #{workspace}")
          raise
        end
      end
              
      # Remove the first part of the druid
      # @param [String] druid
      # @return [String]
      def normalized_druid(druid)
        druid.sub(/druid:/, '')
      end

      def object_dir(dir_type, druid)
        dir_name = File.join(@workspace_base, dir_type, normalized_druid(druid))
        ensure_workspace_exists(dir_name)
        return dir_name
      end

      # The place where the original tar file from google is stored
      def original_dir(druid)
        object_dir('original', druid)
      end

      def content_dir(druid)
        return object_dir('content', druid)
      end

      def metadata_dir(druid)
        return object_dir('metadata', druid)
      end

    end
  end
end