require 'net/https'
require 'uri'
require 'cgi'

module LyberCore
  class Connection
    def Connection.get_https_connection(url)
      https = Net::HTTP.new(url.host, url.port)
      if(url.scheme == 'https')
        https.use_ssl = true
        https.cert = OpenSSL::X509::Certificate.new( File.read(CERT_FILE) )
        https.key = OpenSSL::PKey::RSA.new( File.read(KEY_FILE), KEY_PASS )
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      https
    end

    # Returns body of the HTTP response, or passes the response to the block if it's passed in
    #
    # The following options can be set:
    # :auth_user and :auth_password for basic HTTP authentication.  Both most be set if using this.
    # :content_type if not passed in as an option, then it is set to 'application/xml'
    #
    # Any exceptions thrown while trying to connect should be handled by the caller
    def Connection.connect(full_url, method, body, options = {}, &block)
      url = URI.parse(full_url)
      case method
      when :get
        req = Net::HTTP::Get.new(url.request_uri)
      when :post
        req = Net::HTTP::Post.new(url.request_uri)
      when :put
        req = Net::HTTP::Put.new(url.request_uri)
      end
      req.body = body unless(body.nil?)
      if(options.include?(:content_type))
        req.content_type = options[:content_type]
      else
        req.content_type = 'application/xml'
      end

      if(options.include?(:auth_user))
        req.basic_auth options[:auth_user], options[:auth_password]
      end

      res = Connection.get_https_connection(url).start {|http| http.request(req) }
      case res
      when Net::HTTPSuccess
        if(block_given?)
          block.call(res)
        else
          return res.body
        end
      else
        raise res.error!
      end

    end
  end
  
  
  # Convenience method for performing an HTTP GET using Connection.connect
  def Connection.get(full_url, options, &b)
    Connection.connect(full_url, :get, options, &b)
  end

  # Convenience method for performing an HTTP POST using Connection.connect
  def Connection.post(full_url, body, options = {}, &b)
    Connection.connect(full_url, :post, body, options, &b)
  end

  # Convenience method for performing an HTTP PUT using Connection.connect
  def Connection.put(full_url, body, options = {}, &b)
    Connection.connect(full_url, :put, body, options, &b)
  end


end