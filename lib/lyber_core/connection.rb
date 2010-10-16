require 'net/https'
require 'uri'
require 'cgi'

module LyberCore
  class Connection
    def Connection.get_https_connection(url)
      LyberCore::Log.debug("Establishing connection to #{url.host} on port #{url.port}")
      https = Net::HTTP.new(url.host, url.port)
      if(url.scheme == 'https')
        https.use_ssl = true
        LyberCore::Log.debug("Using SSL")
        https.cert = OpenSSL::X509::Certificate.new( File.read(LyberCore::CERT_FILE) )
        LyberCore::Log.debug("Using cert file #{LyberCore::CERT_FILE}")
        https.key = OpenSSL::PKey::RSA.new( File.read(LyberCore::KEY_FILE), LyberCore::KEY_PASS )
        LyberCore::Log.debug("Using key file #{LyberCore::KEY_FILE} with pass #{LyberCore::KEY_PASS}")
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        LyberCore::Log.debug("https.verify_mode = #{https.verify_mode} (should eql #{OpenSSL::SSL::VERIFY_NONE})")
      end
      https
    end

    # Returns body of the HTTP response, or passes the response to the block if it's passed in
    #
    # == Required Parameters
    # - <b>full_url</b> - A string containing the full url to the resource you're trying to connect to
    # - <b>method</b> - Recognizes the following symbols which correspond to an HTTP verb.  The convenience methods take care of this
    #  :get for HTTP GET
    #  :post for HTTP POST
    #  :put for HTTP PUT
    # - <b>body</b> The body of your request.  Can be nil if you don't have one.
    #
    # == Options
    # - <b>:auth_user</b> for basic HTTP authentication.  :auth_user and :auth_password must both be set if using authentication
    # - <b>:auth_password</b> for basic HTTP authentication. :auth_user and :auth_password must both be set if using authentication
    # - <b>:content_type</b> if not passed in as an option, then it is set to 'application/xml'
    #
    # == Block
    # By default, this method returns the body of the response, Net::HTTPResponse.body .  If you want to work with the Net::HTTPResponse
    # object, you can pass in a block, and the response will be passed to it.
    # 
    # == Exceptions
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
  def Connection.get(full_url, options = {}, &b)
    Connection.connect(full_url, :get, nil, options, &b)
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