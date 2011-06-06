require 'faraday'

class Service
  class << self
    attr_reader :hook_name, :legacy_hook_name

    def hook_name=(value)
      @legacy_hook_name = value
      @hook_name = value.to_s.gsub(/[^a-z]/, '')
      Service::App.service(self)
    end

    def receive(event_type, data, payload)
      svc = new(event_type, data, payload)
      event_method = "receive_#{event_type}"
      if svc.respond_to?(event_method)
        Service::Timeout.timeout(20, TimeoutError) do
          svc.send(event_method)
        end

        true
      else
        false
      end
    end
  end

  attr_reader :event_type
  attr_reader :data
  attr_reader :payload

  attr_writer :faraday
  attr_writer :secret_file
  attr_writer :secrets

  def initialize(event_type, data, payload)
    @event_type = event_type
    @data       = data
    @payload    = payload
    @faraday = nil
  end

  # Public
  def shorten_url(url)
    res = http_get do |req|
      req.url "http://api.bit.ly/shorten",
        :version => '2.0.1',
        :longUrl => url,
        :login   => 'github',
        :apiKey  => 'R_261d14760f4938f0cda9bea984b212e4'
    end

    short = JSON.parse(res.body)
    short["errorCode"].zero? ? short["results"][url]["shortUrl"] : url
  rescue TimeoutError
    url
  end

  # Public
  def http_get(url = nil, headers = nil)
    block = block_given? ? Proc.new : nil
    http_method(:get, url, nil, headers, &block)
  end

  # Public
  def http_post(url = nil, body = nil, headers = nil)
    block = block_given? ? Proc.new : nil
    http_method(:post, url, body, headers, &block)
  end

  # Public
  def http_method(method, url = nil, body = nil, headers = nil)
    faraday.send(method) do |req|
      req.url(url)                if url
      req.headers.update(headers) if headers
      req.body = body             if body
      yield req if block_given?
    end
  end

  def secrets
    @secrets ||=
      File.exist?(secret_file) ? YAML.load_file(secret_file) : {}
  end

  def secret_file
    @secret_file ||= File.expand_path("../../config/secrets.yml")
  end

  def raise_config_error(msg = "Invalid configuration")
    raise GitHub::ServiceConfigurationError, msg
  end

  def faraday(options = {})
    @faraday ||= begin
      options[:timeout] ||= 6
      Faraday.new(options) do |b|
        b.request :url_encoded
        b.adapter :net_http
      end
    end
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
  #
  # Raised when a service hook fails due to bad configuration. Services that
  # fail with this exception may be automatically disabled.
  class ConfigurationError < Error
  end
end
