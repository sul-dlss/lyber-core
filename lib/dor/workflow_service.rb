require 'net/http'
require 'uri'
require 'cgi'
require 'rexml/document'

include REXML

#TODO maybe move methods into workflow_datastream
module Dor
  module WorkflowService
        
  # returns true on success, false otherwise
  def WorkflowService.create_workflow(druid)
    return true unless(Dor::DOR_CREATE_WORKFLOW)
    
    full_uri = ''
    full_uri << Dor::DOR_URI << '/objects/' << druid << '/workflows/etdSubmitWF'
    
    # On success, an empty body is sent   
    LyberCore::Connection.put(full_uri, XML){|response| true}
  rescue Exception => e
    Rails.logger.error("Unable to create workflow\n" << e.to_s)
    return false
  end
  
  # returns true on success, false otherwise
  # PUT "objects/pid:123/workflows/GoogleScannedWF/convert"
  # <process name=\"convert\" status=\"waiting\" datetime=\"2008.11.15 13:30:00 PST\"/>"
  def WorkflowService.update_workflow_status(druid, workflow, process, status)
    return true unless(Dor::DOR_CREATE_WORKFLOW)
    
    uri = ''
    uri << Dor::DOR_URI << '/objects/' << druid << '/workflows/' << workflow << '/' << process
    xml = '<process name="'<< process << '" status="' << status << '"/>' 
    
    # On success, an empty body is sent 
    LyberCore::Connection.put(uri, xml) {|response| true}
  rescue Exception => e
    Rails.logger.error("Unable to update workflow\n" << e.to_s)
    return false
  end
  
    
    
  end
end