require 'rubygems'
require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'
require 'active_fedora'
require 'lyber_core'

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
          $stderr.puts "Datastream " + ds_id + " not found for " + druid
          return nil
       end
    end     
  end
  

end