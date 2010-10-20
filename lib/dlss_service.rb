require 'rubygems'
require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'
require 'active_fedora'
require 'lyber_core'
require 'nokogiri'

class DlssService
  
  # the fedora object to operate on
  attr_reader :fedora_url
  
  def initialize(fedora_url)
    @fedora_url = fedora_url
    solr_url = "http://localhost:8983/solr"
    Fedora::Repository.register(@fedora_url)
    ActiveFedora::SolrService.register(solr_url)
  end
  
  # Get an https connection to the given url
  def get_https_connection(url)
      https = Net::HTTP.new(url.host, url.port)
      if(url.scheme == 'https')
        https.use_ssl = true
        https.cert = OpenSSL::X509::Certificate.new( File.read(CERT_FILE) )
        https.key = OpenSSL::PKey::RSA.new( File.read(KEY_FILE), KEY_PASS )
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      https
  end
  
  # Retrieve the metadata of a datastream of a DOR object
  # e.g. FEDORA_URI + /objects/ + druid + /datastreams/dor gets "dor" datastream metadata
  def get_datastream_md(druid, ds_id)
    begin
      url = URI.parse(@fedora_url + '/objects/' + druid + '/datastreams/' + ds_id)
      req = Net::HTTP::Get.new(url.request_uri)
      req.basic_auth FEDORA_USER, FEDORA_PASS
      res = DorService.get_https_connection(url).start {|http| http.request(req) }  
      case res
        when Net::HTTPSuccess
          return res.body
        else
          LyberCore::Log.error("Datastream " + ds_id + " not found for " + druid)
          return nil
       end
    end     
  end
  
  # This is maintained for backward compatibility, but 
  # get_all_druids_from_object_list or get_some_druids_from_object_list
  # are preferred. 
  def DlssService.get_druids_from_object_list(objectListXml)
    DlssService.get_all_druids_from_object_list(objectListXml)
  end
  
  # Transforms the XML from getObjectsForWorkStep into a list of druids
  def DlssService.get_all_druids_from_object_list(objectListXml)
    DlssService.get_some_druids_from_object_list(objectListXml, nil)
  end
  
  # Takes XML of the form 
  # <objects><object id='druid:hx066mp6063' url='https://lyberservices-test.stanford.edu/workflow/objects/druid:hx066mp6063'/></objects>
  # if count is an integer, return at most that number of druids
  # otherwise, return all druids in the queue
  def DlssService.get_some_druids_from_object_list(objectListXml, count)
    druids = []
    
    # parse the xml into a document object
    xmldoc = Nokogiri::XML::Reader(objectListXml)
    
    xmldoc.each do |node|
        druids << node.attribute("id") unless node.attribute("id").nil?
        break if druids.length == count      
    end
    return druids
  end
  

end