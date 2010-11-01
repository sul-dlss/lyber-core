require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'
require 'rexml/document'

include REXML

class DorService
       
    def DorService.get_https_connection(url)
      https = Net::HTTP.new(url.host, url.port)
      if(url.scheme == 'https')
        https.use_ssl = true
        https.cert = OpenSSL::X509::Certificate.new( File.read(CERT_FILE) )
        https.key = OpenSSL::PKey::RSA.new( File.read(KEY_FILE), KEY_PASS )
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      https
    end
   
  # This should check to see if an object with the given PID already
  # exists in the repository
  def DorService.create_object(form_data)
    begin      
      url = DOR_URI + '/objects'
      body = DorService.encodeParams(form_data)
      content_type = 'application/x-www-form-urlencoded'
      res = LyberCore::Connection.post(url, body, :content_type => content_type)
      res =~ /\/objects\/(.*)/
      druid = $1
      return druid
    rescue Exception => e
      LyberCore::Log.error("Unable to create object #{e.backtrace}")
      raise e
    end  
  end
  
  #objects/dr:123/resources
  #parms: model, id
  #will create object of type dor:GoogleScannedPage
  def DorService.create_child_object(parent_druid, child_id)
    begin
      #See if page exists before creating new fedora object
      # raise "Object exists with id: " + child_id if(DorService.get_druid_by_id(child_id)) 
      form_data = {'model' => 'dor:googleScannedPage', 'id' => child_id}
      url = DOR_URI + '/objects/' + parent_druid + '/resources'
      body = DorService.encodeParams(form_data)
      content_type = 'application/x-www-form-urlencoded'
      res = LyberCore::Connection.post(url, body, :content_type => content_type)
      res=~ /\/resources\/(.*)/
      druid = $1
      LyberCore::Log.info("Child googleScannedPage object created for parent #{parent_druid}") 
      LyberCore::Log.debug("child_id = #{child_id}") 
      LyberCore::Log.debug("new druid = #{druid}")
      return druid
    rescue Exception => e
      LyberCore::Log.error("Unable to create object")
      raise e, "Unable to create object "
    end
  end
  
  
  # Takes a hash of arrays and builds a x-www-form-urlencoded string for POSTing form parameters
  #
  # == Parameters
  # - <b>form_data</b> - a hash of arrays that contains the form data, ie. {'param1' => ['val1', 'val2'], 'param2' => ['val3']}
  def DorService.encodeParams(form_data)
    body = ""
    form_data.each_pair do |param, array|
      array.each do |value|
        encoded = CGI.escape value
        body += '&' unless (body == "")
        body += param + '=' + encoded
      end
    end
    body
  end
 
  
  # Depricated.  Use Dor::WorkflowService#create_workflow in lyber_core gem
  # def DorService.create_workflow(workflow, druid)
  #   begin
  #     url = URI.parse(DOR_URI + '/objects/' + druid + '/workflows/' + workflow.workflow_id)
  #     req = Net::HTTP::Put.new(url.path)
  #     #req.basic_auth 'fedoraUser', 'pass'
  #     req.body = workflow.workflow_process_xml
  #     req.content_type = 'application/xml'
  #     res = DorService.get_https_connection(url).start {|http| http.request(req) }
  #     
  #     WorkflowService.create_workflow()
  #     
  #     case res
  #       when Net::HTTPSuccess
  #         puts workflow.workflow_id + " created for " + druid
  #       else
  #         $stderr.print res.body
  #         raise res.error!
  #     end
  #   rescue Exception => e
  #     $stderr.print "Unable to create workflow " + e
  #     raise
  #   end
  # end
  
 
  # See if an object exists with this dor_id (not druid, but sub-identifier)
  # Caller will have to handle any exception thrown
  def DorService.get_druid_by_id(dor_id)
    url_string = "#{DOR_URI}/query_by_id?id=#{dor_id}"
    LyberCore::Log.debug("Fetching druid for dor_id #{dor_id} at url #{url_string}")
    url = URI.parse(url_string)
    req = Net::HTTP::Get.new(url.request_uri)
    res = DorService.get_https_connection(url).start {|http| http.request(req) }
      
    case res
      when Net::HTTPSuccess
        res.body =~ /druid="([^"\r\n]*)"/
        return $1
      when Net::HTTPClientError
        LyberCore::Log.debug("Barcode does not yet exist in DOR: #{dor_id}") 
        return nil
      when Net::HTTPServerError
        LyberCore::Log.error("Encountered HTTPServerError error when requesting #{url}: #{res.inspect}") 
        raise "Encountered 500 error when requesting #{url}: #{res.inspect}"
      else
        LyberCore::Log.error("Encountered unknown error when requesting #{url}: #{res.inspect}") 
        raise "Encountered unknown error when requesting #{url}: #{res.inspect}"
      end
  end
  
  #############################################  Start of Datastream methods
  # Until ActiveFedora supports client-side certificate configuration, we are stuck with our own methods to access datastreams
  
  #/objects/{pid}/datastreams/{dsID} ? [controlGroup] [dsLocation] [altIDs] [dsLabel] [versionable] [dsState] [formatURI] [checksumType] [checksum] [logMessage]
  def DorService.add_datastream(druid, ds_id, ds_label, xml, content_type='application/xml', versionable = false )
    DorService.add_datastream_managed(druid, ds_id, ds_label, xml, content_type, versionable)
  end
  
  def DorService.add_datastream_external_url(druid, ds_id, ds_label, ext_url, content_type, versionable = false)
    parms = '?controlGroup=E'
    parms += '&dsLabel=' + CGI.escape(ds_label)
    parms += '&versionable=false' unless(versionable)
    parms += '&dsLocation=' + ext_url
    DorService.set_datastream(druid, ds_id, parms, :post, {:type => content_type})
  end
  
  def DorService.update_datastream(druid, ds_id, xml, content_type='application/xml', versionable = false)
    parms = '?controlGroup=M'
    parms += '&versionable=false' unless(versionable)
    DorService.set_datastream(druid, ds_id, parms, :put, {:type => content_type, :xml => xml})
  end
  
  def DorService.add_datastream_managed(druid, ds_id, ds_label, xml, content_type='application/xml', versionable = false )
    parms = '?controlGroup=M'
    parms += '&dsLabel=' + CGI.escape(ds_label)
    parms += '&versionable=false' unless(versionable)
    DorService.set_datastream(druid, ds_id, parms, :post, {:type => content_type, :xml => xml})
  end
    
  # Retrieve the content of a datastream of a DOR object
  # e.g. FEDORA_URI + /objects/ + druid + /datastreams/dor/content gets "dor" datastream content
  def DorService.get_datastream(druid, ds_id)
    begin
      LyberCore::Log.debug("Connecting to #{FEDORA_URI}...")
      url_string = "#{FEDORA_URI}/objects/#{druid}/datastreams/#{ds_id}/content"
      url = URI.parse(url_string)
      LyberCore::Log.debug("Connecting to #{url_string}...")
      req = Net::HTTP::Get.new(url.request_uri)
      LyberCore::Log.debug("request object: #{req.inspect}")
      res = DorService.get_https_connection(url).start {|http| http.request(req) }  
      
      case res
        when Net::HTTPSuccess
          return res.body
        when Net::HTTPClientError
          LyberCore::Log.debug("Datastream not found at url #{url_string}") 
          return nil
        when Net::HTTPServerError
          LyberCore::Log.error("Attempted to reach #{url_string} but failed")
          raise "Encountered 500 error when requesting #{url_string}: #{res.inspect}"
        else
          LyberCore::Log.error("Encountered unknown error when requesting #{url}: #{res.inspect}") 
          raise "Encountered unknown error when requesting #{url}: #{res.inspect}"
        end
     rescue Exception => e
       raise e
     end     
  end

  # Depricated - use Dor::WorkflowService#get_workflow_xml
  def DorService.get_workflow_xml(druid, workflow)
    raise Exception.new("This method is deprecated.  Please use Dor::WorkflowService#get_workflow_xml")
  end
  
  # Retrieve the metadata of a datastream of a DOR object
  # e.g. FEDORA_URI + /objects/ + druid + /datastreams/dor gets "dor" datastream metadata
  def DorService.get_datastream_md(druid, ds_id)
    begin
      LyberCore::Log.debug("Connecting to #{FEDORA_URI}...")
      url = URI.parse(FEDORA_URI + '/objects/' + druid + '/datastreams/' + ds_id)
      LyberCore::Log.debug("Connecting to #{url}...")
      req = Net::HTTP::Get.new(url.request_uri)
      req.basic_auth FEDORA_USER, FEDORA_PASS
      LyberCore::Log.debug("request object: #{req.inspect}")
      res = DorService.get_https_connection(url).start {|http| http.request(req) }  
      case res
        when Net::HTTPSuccess
          return res.body
        else
          LyberCore::Log.error("Attempted to reach #{url} but failed")
          LyberCore::Log.error("Datastream #{dsid} not found for #{druid}")
       end
    rescue Exception => e
      raise e, "Couldn't get datastream from #{url}"
    end     
  end
  
   # Add a new datastream, but only if it does not yet exist
   def DorService.add_datastream_unless_exists(druid, ds_id, ds_label, xml)
      # make sure xml is not empty
      unless xml
        raise "No data supplied for datastream " + ds + "of " + druid
      end
      # check to make sure datastream does not yet exist
      unless DorService.get_datastream(druid, ds_id)
        DorService.add_datastream(druid, ds_id, ds_label, xml)
      end
  end
  
  #############################################  End of Datastream methods

  
  # Deprecated.  Use Dor::WorkflowService#update_workflow_status
  #PUT "objects/pid:123/workflows/GoogleScannedWF/convert"
  #<process name=\"convert\" status=\"waiting\" elapsed="0.11" lifecycle="released" "/>"
  #TODO increment attempts
  # def DorService.updateWorkflowStatus(repository, druid, workflow, process, status, elapsed = 0, lifecycle = nil)
  #   begin
  #     url = URI.parse(WORKFLOW_URI + '/' + repository + '/objects/' + druid + '/workflows/' + workflow + '/' + process)
  #     req = Net::HTTP::Put.new(url.path)
  #     process_xml = '<process name="'+ process + '" status="' + status + '" ' 
  #     process_xml << 'elapsed="' + elapsed.to_s + '" '
  #     process_xml << 'lifecycle="' + lifecycle + '" ' if(lifecycle)
  #     process_xml << '/>' 
  #     req.body = process_xml
  #     req.content_type = 'application/xml'
  #     res = DorService.get_https_connection(url).start {|http| http.request(req) }
  #     case res
  #       when Net::HTTPSuccess
  #         puts "#{workflow} process updated for " + druid
  #       else
  #         $stderr.print res.body
  #         raise res.error!
  #     end
  #   rescue Exception => e
  #     $stderr.print "Unable to update workflow " + e
  #     raise
  #   end
  #   
  # end
  
  # Returns string containing object list XML from a DOR query
  # XML returned looks like:
  #   <objects>
  #     <object druid="dr:123" url="http://localhost:9999/jersey-spring/objects/dr:123%5c" />
  #     <object druid="dr:abc" url="http://localhost:9999/jersey-spring/objects/dr:abc%5c" />
  #   </objects>
  def DorService.get_objects_for_workstep(repository, workflow, completed, waiting)
    LyberCore::Log.debug("DorService.get_objects_for_workstep(#{repository}, #{workflow}, #{completed}, #{waiting})")
    begin  
      if repository.nil? or workflow.nil? or completed.nil? or waiting.nil?
        LyberCore::Log.fatal("Can't execute DorService.get_objects_for_workstep: missing info")
      end
      
      unless defined?(WORKFLOW_URI) and WORKFLOW_URI != nil
        LyberCore::Log.fatal("WORKFLOW_URI is not set. ROBOT_ROOT = #{ROBOT_ROOT}")
        raise "WORKFLOW_URI is not set"   
      end
      
      uri_string = "#{WORKFLOW_URI}/workflow_queue?repository=#{repository}&workflow=#{workflow}&completed=#{completed}&waiting=#{waiting}"
      LyberCore::Log.info("Attempting to connect to #{uri_string}")
      url = URI.parse(uri_string)
      req = Net::HTTP::Get.new(url.request_uri)
      res = DorService.get_https_connection(url).start {|http| http.request(req) }  
      case res
        when Net::HTTPSuccess
          return res.body
        else
          LyberCore::Log.fatal("Workflow queue not found for #{workflow} : #{waiting}")
          LyberCore::Log.debug("I am attempting to connect to WORKFLOW_URI #{WORKFLOW_URI}")
          LyberCore::Log.debug("repository: #{repository}")
          LyberCore::Log.debug("workflow: #{workflow}")
          LyberCore::Log.debug("completed: #{completed}")
          LyberCore::Log.debug("waiting: #{waiting}")
          LyberCore::Log.debug(res.inspect)
          raise "Could not connect to url #{uri_string}"
       end
    end 
  end
  
  # Transforms the XML from getObjectsForWorkStep into a list of druids
  # TODO figure out how to return a partial list
  # This method is here for backward compatibility, but it has
  # been superceded by DlssService.get_druids_from_object_list(objectListXml)
  def DorService.get_druids_from_object_list(objectListXml)
    DlssService.get_all_druids_from_object_list(objectListXml)
  end
  
  # Retrieves the identityMetadata datastream for a DOR object,
  # extracts the otherId values, and returns them in a hash
  def DorService.get_object_identifiers(druid)
    begin
    identifiers = {}
    identityMetadata = get_datastream(druid, 'identityMetadata')
    raise "Unable to get identityMetadata datastream for #{druid}" if identityMetadata.nil?
    dorXml = Document.new(identityMetadata)
    
    dorXml.elements.each("identityMetadata/otherId") do |element| 
      identifiers[element.attributes["name"]] = case element.text
        when nil then nil
        else element.text.strip     
      end
    end
    return identifiers   
    rescue Exception => e
      raise e, "Couldn't get object identifiers for #{druid}"
    end 
  end
  
  def DorService.transfer_object(objectid, sourceDir, destinationDir) 
    rsync='rsync -a -e ssh '
    rsync_cmd = rsync + "'" + sourceDir + objectid + "' " +  destinationDir
    print rsync_cmd + "\n"
    system(rsync_cmd)
    return File.exists?(File.join(destinationDir, objectid))
  end
  
  def DorService.verify_checksums(directory, checksumFile)
    dirSave = Dir.pwd
    Dir.chdir(directory)
    checksumCmd = 'md5sum -c ' + checksumFile + ' | grep -v OK | wc -l'
    badcount = `#{checksumCmd}`.to_i
    Dir.chdir(dirSave)
    return (badcount==0)
  end
  
  # Given a process and an error message, constuct an xml fragment that can be
  # posted to the workflow service to record the error generated for a given druid
  def DorService.construct_error_update_request(process, error_msg, error_txt)
    clean_error_msg = error_msg.gsub(/\s+/," ").gsub(/[`'#<>]/,'').gsub(/"/,"'")
    clean_error_txt = error_txt.gsub(/\s+/," ").gsub(/[`'#<>]/,'').gsub(/"/,"'") unless error_txt.nil?
    body = '<process name="'+ process + '" status="error" errorMessage="' + clean_error_msg + '" ' 
    body += 'errorText="' + clean_error_txt + '" ' unless error_txt.nil?
    body += '/>'  
    return body
  end
  
  # If an object encounters an error during processing, set its status to "error"
  def DorService.update_workflow_error_status(repository, druid, workflow, process, error_msg, error_txt = nil)
    begin
      LyberCore::Log.debug("Updating workflow error status for druid #{druid}")
      LyberCore::Log.debug("Error message is: #{error_msg}")
      LyberCore::Log.debug("Error text is: #{error_txt}") 
      url_string = "#{WORKFLOW_URI}/#{repository}/objects/#{druid}/workflows/#{workflow}/#{process}"
      url = URI.parse(url_string)
      LyberCore::Log.debug("Using url #{url_string}")
      req = Net::HTTP::Put.new(url.path)
      req.body = DorService.construct_error_update_request(process, error_msg, error_txt)
      req.content_type = 'application/xml'
      LyberCore::Log::debug("Putting request: #{req.inspect}")
      res = DorService.get_https_connection(url).start {|http| http.request(req) }
      LyberCore::Log::debug("Got response: #{res.inspect}")
      case res
       when Net::HTTPSuccess
         LyberCore::Log.error("#{workflow} - #{process} set to error for " + druid)
       else
         LyberCore::Log.error(res.body)
         raise res.error!, "Received error from the workflow service"
      end
    rescue Exception => e
      msg = "Unable to update workflow service at url #{url_string}"
      LyberCore::Log.error(msg)
      raise e, msg
    end
  end

    # This method sends a GET request to jenson and returns MARC XML
    def DorService.query_symphony(flexkey)
      begin
        symphony_url = 'http://zaph.stanford.edu'
        path_info = '/cgi-bin/holding.pl?'
        parm_list = URI.escape('search=location&flexkey=' + flexkey)
        url_string = symphony_url + path_info + parm_list

        url = URI.parse(url_string)
        LyberCore::Log.debug("Attempting to query symphony: #{url_string}")
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.get( path_info + parm_list )
        }
        case res
          when Net::HTTPSuccess
            LyberCore::Log.debug("Successfully queried symphony for #{flexkey}")
            return res.body          
          else
            LyberCore::Log.error("Encountered an error from symphony: #{res.body}")
            raise res.error!
        end
      rescue Exception => e
        raise e, "Encountered an error from symphony"
      end

     end #query_symphony


  private
  # druid, ds, url, content_type, method, parms
  def DorService.set_datastream(druid, ds_id, parms, method, content = {})
    begin  
      url = URI.parse(FEDORA_URI + '/objects/' + druid + '/datastreams/' + ds_id + parms)
      case method
        when :post
          req = Net::HTTP::Post.new(url.request_uri)
        when :put
          req = Net::HTTP::Put.new(url.request_uri)
      end
      req.basic_auth FEDORA_USER, FEDORA_PASS
      req.body = content[:xml] if(content[:xml])
      req.content_type = content[:type]
      res = DorService.get_https_connection(url).start {|http| http.request(req) }
      case res
        when Net::HTTPSuccess
          return true
        else
          $stderr.print res.body
          raise res.error!
      end
    rescue Exception => e
      raise
    end 
  end
  
  def DorService.get_object_metadata(druid) 
    dor = DorService.get_datastream(druid, 'identityMetadata')
    mods = DorService.get_datastream(druid, 'descMetadata')
    googlemets = DorService.get_datastream(druid, 'googlemets')
    contentMetadata = DorService.get_datastream(druid, 'contentMetadata')
    adminMetadata = DorService.get_datastream(druid, 'adminMetadata')
    xml = "<objectMD druid='" + druid + "' >\n" + 
      dor + mods + googlemets + contentMetadata + adminMetadata +
      "</objectMD>\n"
    return xml
  end
  
end

  # Given an array of strings, construct valid xml in which each
  # member of the array becomes a <tag> element
  def DorService.construct_xml_for_tag_array(tag_array)
    xml = "<tags>"
    tag_array.each do |tag|
      tag = tag.gsub(/\s+/," ").gsub(/[<>!]/,'')
      xml << "<tag>#{tag}</tag>"
    end
    xml << "</tags>"
  end

  
  def DorService.add_identity_tags(druid, tags)
   begin
     url = URI.parse(DOR_URI + '/objects/' + druid + '/datastreams/identityMetadata/tags' )
     req = Net::HTTP::Put.new(url.path)
     req.body = DorService.construct_xml_for_tag_array(tags)
     req.content_type = 'application/xml'
     res = DorService.get_https_connection(url).start {|http| http.request(req) }
     case res
       when Net::HTTPSuccess
         return true
       else
         LyberCore::Log.error(res.body)
         raise res.error!
     end
   rescue Exception => e
     raise e
   end
  end

#DorService.updateWorkflowStatus('dr:rf624mb644', 'GoogleScannedWF', 'descriptive-metadata', 'completed')
####Testing
#line = 'id="catkey:1990757"||id="barcode:36105045033136"||model="GoogleScannedBook"||label="The poacher"'
#form_data = {}
#DorService.parse_line_return_hashlist(line, form_data)
#form_data.each_pair{|k,v| puts "key: #{k} value: #{v}"}
#
#puts DorService.encodeParams(form_data)

#DorService.create_object('id="catkey:454545454545454"||id="barcode:434343434343434343434343434"||model="GoogleScannedBook"||label="Ruby multiple Id parms 3"')

