module LyberCore
    
  class LyberCore::Destroyer
    
  require 'rubygems'
  require 'active-fedora'
  require 'open-uri'
  
  attr_reader :repository
  attr_reader :workflow
  attr_reader :registration_robot
  attr_reader :druid_list
  
  # Given a repository, a workflow and the name of a robot that registers objects in fedora
  # we can generate a list of all the druids that were created by that robot
  def initialize(repository, workflow, registration_robot)
    @repository = repository
    @workflow = workflow
    @registration_robot = registration_robot
    @druid_list = self.get_druid_list
  end
  
  def get_druid_list
    begin
      druid_list = []
      url_string = "#{WORKFLOW_URI}/workflow_queue?repository=#{@repository}&workflow=#{@workflow}&completed=#{@registration_robot}"
      LyberCore::Log.debug("Fetching druids from #{url_string}")
      doc = Nokogiri::XML(open(url_string))
      doc.xpath("//objects/object/@id").each do |id|
        druid_list << id.to_s
      end
      return druid_list
    rescue Exception => e
      raise e, "Couldn't fetch druid list from #{url_string}"
    end
  end
    
    # Iterate through the druids in @druid_list and delete each of them from FEDORA
    def delete_druids
      connect_to_fedora
      @druid_list.each do |druid|
        LyberCore::Log.info("Deleting #{druid}")
        obj = ActiveFedora::Base.load_instance(druid)
        obj.delete
      end
    end
    
    def connect_to_fedora
      begin
        if @repository == "dor"
          repo_url = FEDORA_URI
        elsif @repository == "sdr"
          repo_url = SEDORA_URI
        else
          raise "I don't know how to connect to repository #{@repository}"
        end
        LyberCore::Log.debug("connecting to #{repo_url}")
        Fedora::Repository.register(repo_url)
      rescue Errno::ECONNREFUSED => e
       raise e, "Can't connect to Fedora at url #{repo_url}"
      end
    end
  end
end