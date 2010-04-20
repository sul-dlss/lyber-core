
#TODO maybe move methods into workflow_datastream
module Dor
  module WorkflowService
        
  # returns true on success, false otherwise
  def WorkflowService.create_workflow(druid, workflow_name, wf_xml = WF_XML)
    return true unless(Dor::DOR_CREATE_WORKFLOW)
    
    full_uri = ''
    full_uri << Dor::DOR_URI << '/objects/' << druid << '/workflows/' << workflow_name
    
    # On success, an empty body is sent   
    LyberCore::Connection.put(full_uri, wf_xml){|response| true}
  rescue Exception => e
    Rails.logger.error("Unable to create workflow\n" << e.to_s)
    return false
  end
  
  # returns true on success, false otherwise
  # PUT "objects/pid:123/workflows/GoogleScannedWF/convert"
  # <process name=\"convert\" status=\"waiting\" datetime=\"2008.11.15 13:30:00 PST\"/>"
  def WorkflowService.update_workflow_status(druid, workflow, process, status, elapsed = 0, lifecycle = nil)
    return true unless(Dor::DOR_CREATE_WORKFLOW)
    
    uri = ''
    uri << Dor::DOR_URI << '/objects/' << druid << '/workflows/' << workflow << '/' << process    
    process_xml = '<process name="'+ process + '" status="' + status + '" ' 
    process_xml << 'elapsed="' + elapsed.to_s + '" '
    process_xml << 'lifecycle="' + lifecycle + '" ' if(lifecycle)
    process_xml << '/>' 
    
    # On success, an empty body is sent 
    LyberCore::Connection.put(uri, process_xml) {|response| true}
  rescue Exception => e
    Rails.logger.error("Unable to update workflow\n" << e.to_s)
    return false
  end
  
    
    
  end
end