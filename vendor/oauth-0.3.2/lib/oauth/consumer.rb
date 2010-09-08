require 'net/http'
require 'net/https'
require 'oauth/client/net_http'
require 'oauth/errors'

module OAuth
  class Consumer
    # determine the certificate authority path to verify SSL certs
    CA_FILES = %w(/etc/ssl/certs/ca-certificates.crt /usr/share/curl/curl-ca-bundle.crt)
    CA_FILES.each do |ca_file|
      if File.exists?(ca_file)
        CA_FILE = ca_file
        break
      end
    end
    CA_FILE = nil unless defined?(CA_FILE)

    @@default_options = {
      # Signature method used by server. Defaults to HMAC-SHA1
      :signature_method   => 'HMAC-SHA1',

      # default paths on site. These are the same as the defaults set up by the generators
      :request_token_path => '/oauth/request_token',
      :authorize_path     => '/oauth/authorize',
      :access_token_path  => '/oauth/access_token',

      # How do we send the oauth values to the server see
      # http://oauth.net/core/1.0/#consumer_req_param for more info
      #
      # Possible values:
      #
      #   :header - via the Authorize header (Default) ( option 1. in spec)
      #   :body - url form encoded in body of POST request ( option 2. in spec)
      #   :query_string - via the query part of the url ( option 3. in spec)
      :scheme        => :header,

      # Default http method used for OAuth Token Requests (defaults to :post)
      :http_method   => :post,

      :oauth_version => "1.0"
    }

    attr_accessor :options, :key, :secret
    attr_writer   :site, :http

    # Create a new consumer instance by passing it a configuration hash:
    #
    #   @consumer = OAuth::Consumer.new(key, secret, {
    #     :site               => "http://term.ie",
    #     :scheme             => :header,
    #     :http_method        => :post,
    #     :request_token_path => "/oauth/example/request_token.php",
    #     :access_token_path  => "/oauth/example/access_token.php",
    #     :authorize_path     => "/oauth/example/authorize.php"
    #    })
    #
    # Start the process by requesting a token
    #
    #   @request_token = @consumer.get_request_token
    #   session[:request_token] = @request_token
    #   redirect_to @request_token.authorize_url
    #
    # When user returns create an access_token
    #
    #   @access_token = @request_token.get_access_token
    #   @photos=@access_token.get('/photos.xml')
    #
    def initialize(consumer_key, consumer_secret, options = {})
      @key    = consumer_key
      @secret = consumer_secret

      # ensure that keys are symbols
      @options = @@default_options.merge(options.inject({}) { |options, (key, value)|
        options[key.to_sym] = value
        options
      })
    end

    # The default http method
    def http_method
      @http_method ||= @options[:http_method] || :post
    end

    # The HTTP object for the site. The HTTP Object is what you get when you do Net::HTTP.new
    def http
      @http ||= create_http
    end

    # Contains the root URI for this site
    def uri(custom_uri = nil)
      if custom_uri
        @uri  = custom_uri
        @http = create_http # yike, oh well. less intrusive this way
      else  # if no custom passed, we use existing, which, if unset, is set to site uri
        @uri ||= URI.parse(site)
      end
    end

    # Makes a request to the service for a new OAuth::RequestToken
    #
    #  @request_token = @consumer.get_request_token
    #
    def get_request_token(request_options = {}, *arguments)
      response = token_request(http_method, (request_token_url? ? request_token_url : request_token_path), nil, request_options, *arguments)
      OAuth::RequestToken.new(self, response[:oauth_token], response[:oauth_token_secret])
    end

    # Creates, signs and performs an http request.
    # It's recommended to use the OAuth::Token classes to set this up correctly.
    # The arguments parameters are a hash or string encoded set of parameters if it's a post request as well as optional http headers.
    #
    #   @consumer.request(:get,  '/people', @token, { :scheme => :query_string })
    #   @consumer.request(:post, '/people', @token, {}, @person.to_xml, { 'Content-Type' => 'application/xml' })
    #
    def request(http_method, path, token = nil, request_options = {}, *arguments)
      if path !~ /^\//
        @http = create_http(path)
        _uri = URI.parse(path)
        path = "#{_uri.path}#{_uri.query ? "?#{_uri.query}" : ""}"
      end

      rsp = http.request(create_signed_request(http_method, path, token, request_options, *arguments))

      # check for an error reported by the Problem Reporting extension
      # (http://wiki.oauth.net/ProblemReporting)
      # note: a 200 may actually be an error; check for an oauth_problem key to be sure
      if !(headers = rsp.to_hash["www-authenticate"]).nil? &&
        (h = headers.select { |h| h =~ /^OAuth / }).any? &&
        h.first =~ /oauth_problem/

        # puts "Header: #{h.first}"

        # TODO doesn't handle broken responses from api.login.yahoo.com
        # remove debug code when done
        params = OAuth::Helper.parse_header(h.first)

        # puts "Params: #{params.inspect}"
        # puts "Body: #{rsp.body}"

        raise OAuth::Problem.new(params.delete("oauth_problem"), rsp, params)
      end

      rsp
    end

    # Creates and signs an http request.
    # It's recommended to use the Token classes to set this up correctly
    def create_signed_request(http_method, path, token = nil, request_options = {}, *arguments)
      request = create_http_request(http_method, path, *arguments)
      sign!(request, token, request_options)
      request
    end

    # Creates a request and parses the result as url_encoded. This is used internally for the RequestToken and AccessToken requests.
    def token_request(http_method, path, token = nil, request_options = {}, *arguments)
      response = request(http_method, path, token, request_options, *arguments)

      case response.code.to_i

      when (200..299)
        CGI.parse(response.body).inject({}) { |h,(k,v)| h[k.to_sym] = v.first; h }
      when (300..399)
        # this is a redirect
        response.error!
      when (400..499)
        raise OAuth::Unauthorized, response
      else
        response.error!
      end
    end

    # Sign the Request object. Use this if you have an externally generated http request object you want to sign.
    def sign!(request, token = nil, request_options = {})
      request.oauth!(http, self, token, options.merge(request_options))
    end

    # Return the signature_base_string
    def signature_base_string(request, token = nil, request_options = {})
      request.signature_base_string(http, self, token, options.merge(request_options))
    end

    def site
      @options[:site].to_s
    end

    def scheme
      @options[:scheme]
    end

    def request_token_path
      @options[:request_token_path]
    end

    def authorize_path
      @options[:authorize_path]
    end

    def access_token_path
      @options[:access_token_path]
    end

    # TODO this is ugly, rewrite
    def request_token_url
      @options[:request_token_url] || site + request_token_path
    end

    def request_token_url?
      @options.has_key?(:request_token_url)
    end

    def authorize_url
      @options[:authorize_url] || site + authorize_path
    end

    def authorize_url?
      @options.has_key?(:authorize_url)
    end

    def access_token_url
      @options[:access_token_url] || site + access_token_path
    end

    def access_token_url?
      @options.has_key?(:access_token_url)
    end

  protected

    # Instantiates the http object
    def create_http(_url = nil)
      if _url.nil? || _url[0] =~ /^\//
        our_uri = URI.parse(site)
      else
        our_uri = URI.parse(_url)
      end

      http_object = Net::HTTP.new(our_uri.host, our_uri.port)

      http_object.use_ssl = (our_uri.scheme == 'https')

      if CA_FILE
        http_object.ca_file = CA_FILE
        http_object.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http_object.verify_depth = 5
      else
        http_object.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http_object
    end

    # create the http request object for a given http_method and path
    def create_http_request(http_method, path, *arguments)
      http_method = http_method.to_sym

      if [:post, :put].include?(http_method)
        data = arguments.shift
      end

      headers = arguments.first.is_a?(Hash) ? arguments.shift : {}

      case http_method
      when :post
        request = Net::HTTP::Post.new(path,headers)
        request["Content-Length"] = 0 # Default to 0
      when :put
        request = Net::HTTP::Put.new(path,headers)
        request["Content-Length"] = 0 # Default to 0
      when :get
        request = Net::HTTP::Get.new(path,headers)
      when :delete
        request =  Net::HTTP::Delete.new(path,headers)
      when :head
        request = Net::HTTP::Head.new(path,headers)
      else
        raise ArgumentError, "Don't know how to handle http_method: :#{http_method.to_s}"
      end

      if data.is_a?(Hash)
        request.set_form_data(data)
      elsif data
        request.body = data.to_s
        request["Content-Length"] = request.body.length
      end

      request
    end

    # Unset cached http instance because it cannot be marshalled when
    # it has already been used and use_ssl is set to true
    def marshal_dump(*args)
      @http = nil
      self
    end
  end
end
