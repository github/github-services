require 'faraday'

# Represents a single triggered Service call.  Each Service tracks the event
# type, the configuration data, and the payload for the current call.
class Service
  dir = File.expand_path '..', __FILE__
  Dir["#{dir}/events/*.rb"].each do |helper|
    require helper
  end

  class << self
    attr_accessor :root, :env, :host

    %w(development test production staging fi).each do |m|
      define_method "#{m}?" do
        env == m
      end
    end

    # Gets a StatsD client.
    def stats
      if @stats.nil?
        if (hash = secrets['statsd']) && url = hash[env]
          uri   = Addressable::URI.parse(url)
          stats = Statsd.new uri.host, uri.port 
          stats.namespace = 'services'
          @stats = stats
        end
        @stats ||= false
      end
      @stats || nil
    end

    attr_writer :stats

    # The SHA1 of the commit that was HEAD when the process started. This is
    # used in production to determine which version of the app is deployed.
    #
    # Returns the 40 char commit SHA1 string.
    def current_sha
      @current_sha ||=
        `cd #{root}; git rev-parse HEAD 2>/dev/null || echo unknown`.
        chomp.freeze
    end

    attr_writer :current_sha

    # Public: Processes an incoming Service event.
    #
    # event   - A symbol identifying the event type.  Example: :push
    # data    - A Hash with the configuration data for the Service.
    # payload - A Hash with the unique payload data for this Service instance.
    #
    # Returns true if the Service responded to the event, or false if the
    # Service does not respond to this event.
    def receive(event, data, payload = nil)
      svc = new(event, data, payload)

      event_method = "receive_#{event}"
      if svc.respond_to?(event_method)
        Service::Timeout.timeout(20, TimeoutError) do
          svc.send(event_method)
        end

        true
      else
        false
      end
    end

    # Tracks the defined services.
    #
    # Returns an Array of Service Classes.
    def services
      @services ||= []
    end

    # Gets the current schema for the data attributes that this Service
    # expects.  This schema is used to generate the GitHub repository admin
    # interface.  The attribute types loosely to HTML input elements.
    #
    # Example:
    #
    #   class FooService < Service
    #     string :token
    #   end
    #
    #   FooService.schema
    #   # => [[:string, :token]]
    #
    # Returns an Array of [Symbol, String] tuples.
    def schema
      @schema ||= []
    end

    # Public: Adds the given attributes as String attributes in the Service's
    # schema.
    #
    # Example:
    #
    #   class FooService < Service
    #     string :token
    #   end
    #
    #   FooService.schema
    #   # => [[:string, :token]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def string(*attrs)
      add_to_schema :string, attrs
    end

    # Public: Adds the given attributes as Password attributes in the Service's
    # schema.
    #
    # Example:
    #
    #   class FooService < Service
    #     password :token
    #   end
    #
    #   FooService.schema
    #   # => [[:password, :token]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def password(*attrs)
      add_to_schema :password, attrs
    end

    # Public: Adds the given attributes as Boolean attributes in the Service's
    # schema.
    #
    # Example:
    #
    #   class FooService < Service
    #     boolean :digest
    #   end
    #
    #   FooService.schema
    #   # => [[:boolean, :digest]]
    #
    # *attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def boolean(*attrs)
      add_to_schema :boolean, attrs
    end

    # Adds the given attributes to the Service's data schema.
    #
    # type  - A Symbol specifying the type: :string, :password, :boolean.
    # attrs - Array of Symbol attribute names.
    #
    # Returns nothing.
    def add_to_schema(type, attrs)
      attrs.each do |attr|
        schema << [type, attr.to_sym]
      end
    end

    # Gets the official title of this Service.  This is used in any
    # user-facing documentation regarding the Service.
    #
    # Returns a String.
    def title
      @title ||= begin
        hook = name.dup
        hook.sub! /.*:/, ''
        hook
      end
    end

    # Sets the official title of this Service.
    #
    # title - The String title.
    #
    # Returns nothing.
    attr_writer :title

    # Gets the name that identifies this Service type.  This is a
    # short string that is used to uniquely identify the service internally.
    #
    # Returns a String.
    def hook_name
      @hook_name ||= begin
        hook = name.dup
        hook.downcase!
        hook.sub! /.*:/, ''
        hook
      end
    end

    # Public: Gets the Hash of secret configuration options.  These are set on
    # the GitHub servers and never committed to git.
    #
    # Returns a Hash.
    def secrets
      @secrets ||=
        (File.exist?(secret_file) && YAML.load_file(secret_file)) || {}
    end

    # Public: Gets the Hash of email configuration options.  These are set on
    # the GitHub servers and never committed to git.
    #
    # Returns a Hash.
    def email_config
      @email_config ||=
        (File.exist?(email_config_file) && YAML.load_file(email_config_file)) || {}
    end

    # Gets the path to the secret configuration file.
    #
    # Returns a String path.
    def secret_file
      @secret_file ||= File.expand_path("../../config/secrets.yml", __FILE__)
    end

    # Gets the path to the email configuration file.
    #
    # Returns a String path.
    def email_config_file
      @email_config_file ||= File.expand_path('../../config/email.yml', __FILE__)
    end

    # Sets the path to the secrets configuration file.
    #
    # secret_file - String path.
    #
    # Returns nothing.
    attr_writer :secret_file

    # Sets the default private configuration data for all Services.
    #
    # secrets - Configuration Hash.
    #
    # Returns nothing.
    attr_writer :secrets

    # Sets the path to the email configuration file.
    #
    # email_config_file - The String path.
    #
    # Returns nothing.
    attr_writer :email_config_file

    # Sets the default email configuration data for all Services.
    #
    # email_config - Email configuration Hash.
    #
    # Returns nothing.
    attr_writer :email_config

    # Binds the current Service to the Sinatra App.
    #
    # Returns nothing.
    def inherited(svc)
      Service.services << svc
      Service::App.service(svc)
      super
    end
  end

  # Determine #root from this file's location
  self.root ||= File.expand_path('../..', __FILE__)
  self.host ||= `hostname -s`.chomp

  # Determine #env from the environment
  self.env ||= ENV['RACK_ENV'] || ENV['GEM_STRICT'] ? 'production' : 'development'

  # Public: Gets the configuration data for this Service instance.
  #
  # Returns a Hash.
  attr_reader :data

  # Public: Gets the unique payload data for this Service instance.
  #
  # Returns a Hash.
  attr_reader :payload

  # Public: Gets the identifier for the Service's event.
  #
  # Returns a Symbol.
  attr_reader :event

  # Sets the Faraday::Connection for this Service instance.
  #
  # http - New Faraday::Connection instance.
  #
  # Returns a Faraday::Connection.
  attr_writer :http

  # Sets the private configuration data.
  #
  # secrets - Configuration Hash.
  #
  # Returns nothing.
  attr_writer :secrets

  # Sets the email configuration data.
  #
  # email_config - Email configuration Hash.
  #
  # Returns nothing.
  attr_writer :email_config

  # Sets the path to the SSL Certificate Authority file.
  #
  # ca_file - String path.
  #
  # Returns nothing.
  attr_writer :ca_file

  def initialize(event = :push, data = {}, payload = nil)
    helper_name = "#{event.to_s.capitalize}Helpers"
    if Service.const_defined?(helper_name)
      @helper = Service.const_get(helper_name)
      extend @helper
    else
      raise ArgumentError, "Invalid event: #{event.inspect}"
    end

    @event   = event
    @data    = data
    @payload = payload || sample_payload
    @http = @secrets = @email_config = nil
  end

  # Public: Shortens the given URL with bit.ly.
  #
  # url - String URL to be shortened.
  #
  # Returns the String URL response from bit.ly.
  def shorten_url(url)
    res = http_post("http://git.io", :url => url)
    if res.status == 201
      res.headers['location']
    else
      url
    end
  rescue TimeoutError
    url
  end

  # Public: Makes an HTTP GET call.
  #
  # url     - Optional String URL to request.
  # params  - Optional Hash of GET parameters to set.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_get("http://github.com")
  #   # => <Faraday::Response>
  #
  #   # GET http://github.com?page=1
  #   http_get("http://github.com", :page => 1)
  #   # => <Faraday::Response>
  #
  #   http_get("http://github.com", {:page => 1},
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_get "http://github.com" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1
  #     req.headers['Accept'] = 'application/json'
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_get(url = nil, params = nil, headers = nil)
    http.get do |req|
      req.url(url)                if url
      req.params.update(params)   if params
      req.headers.update(headers) if headers
      yield req if block_given?
    end
  end

  # Public: Makes an HTTP POST call.
  #
  # url     - Optional String URL to request.
  # body    - Optional String Body of the POST request.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_post("http://github.com/create", "foobar")
  #   # => <Faraday::Response>
  #
  #   http_post("http://github.com/create", "foobar",
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_post "http://github.com/create" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1 # http://github.com/create?page=1
  #     req.headers['Content-Type'] = 'application/json'
  #     req.body = {:foo => :bar}.to_json
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_post(url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?
    http_method :post, url, body, headers, &block
  end

  # Public: Makes an HTTP call.
  #
  # method  - Symbol of the HTTP method.  Example: :put
  # url     - Optional String URL to request.
  # body    - Optional String Body of the POST request.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_method(:put, "http://github.com/create", "foobar")
  #   # => <Faraday::Response>
  #
  #   http_method(:put, "http://github.com/create", "foobar",
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_method :put, "http://github.com/create" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1 # http://github.com/create?page=1
  #     req.headers['Content-Type'] = 'application/json'
  #     req.body = {:foo => :bar}.to_json
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_method(method, url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?

    check_ssl do
      http.send(method) do |req|
        req.url(url)                if url
        req.headers.update(headers) if headers
        req.body = body             if body
        block.call req if block
      end
    end
  end

  # Public: Lazily loads the Faraday::Connection for the current Service
  # instance.
  #
  # options - Optional Hash of Faraday::Connection options.
  #
  # Returns a Faraday::Connection instance.
  def http(options = {})
    @http ||= begin
      options[:timeout]            ||= 6
      options[:ssl]                ||= {}
      options[:ssl][:ca_file]      ||= ca_file
      options[:ssl][:verify_depth] ||= 5

      Faraday.new(options) do |b|
        b.request :url_encoded
        b.adapter :net_http
      end
    end
  end

  # Public: Checks for an SSL error, and re-raises a Services configuration error.
  #
  # Returns nothing.
  def check_ssl
    yield
  rescue OpenSSL::SSL::SSLError => e
    raise_config_error "Invalid SSL cert"
  end

  # Public: Gets the Hash of secret configuration options.  These are set on
  # the GitHub servers and never committed to git.
  #
  # Returns a Hash.
  def secrets
    @secrets || Service.secrets
  end

  # Public: Gets the Hash of email configuration options.  These are set on
  # the GitHub servers and never committed to git.
  #
  # Returns a Hash.
  def email_config
    @email_config || Service.email_config
  end

  # Public: Raises a configuration error inside a service, and halts further
  # processing.
  #
  # Raises a Service;:ConfigurationError.
  def raise_config_error(msg = "Invalid configuration")
    raise ConfigurationError, msg
  end

  # Gets the path to the SSL Certificate Authority certs.  These were taken
  # from: http://curl.haxx.se/ca/cacert.pem
  #
  # Returns a String path.
  def ca_file
    @ca_file ||= File.expand_path('../../config/cacert.pem', __FILE__)
  end

  # Generates a sample payload for the current Service instance.
  #
  # Returns a Hash payload.
  def sample_payload
    @helper.sample_payload
  end

  # Raised when an unexpected error occurs during service hook execution.
  class Error < StandardError
    attr_reader :original_exception
    def initialize(message, original_exception=nil)
      original_exception = message if message.kind_of?(Exception)
      @original_exception = original_exception
      super(message)
    end
  end

  class TimeoutError < Timeout::Error
  end

  # Raised when a service hook fails due to bad configuration. Services that
  # fail with this exception may be automatically disabled.
  class ConfigurationError < Error
  end
end

begin
  require 'system_timer'
  Service::Timeout = SystemTimer
rescue LoadError
  require 'timeout'
  Service::Timeout = Timeout
end

