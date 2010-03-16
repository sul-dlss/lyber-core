require 'net/https'
require 'active_fedora'

module Dor
  class SuriService
    
    # Returns ID_NAMESPACE:id_from_suri
    # Throws an exception if there were any problems
    def self.mint_id
      unless(MINT_SURI_IDS)
        return Fedora::Repository.instance.nextid
      end
      
      #Post with no body
      id = LyberCore::Connection.post("#{SURI_URL}/suri2/namespaces/#{ID_NAMESPACE}/identifiers", nil, 
                                :auth_user => SURI_USER, :auth_password => SURI_PASSWORD)

      return "#{ID_NAMESPACE}:#{id.strip}"

    rescue Exception => e
      Rails.logger.error("Unable to mint id from suri: #{e.to_s}")
      raise e
    end
  
    
  end
end