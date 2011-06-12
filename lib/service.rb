require 'faraday'

class Service
  dir = File.expand_path '..', __FILE__
  Dir["#{dir}/service/*.rb"].each do |helper|
    require helper
  end

  include PushHelpers

  class << self
    # Public
    def receive(event_type, data, payload)
      svc = new(data, payload)
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

    def hook_name
      @hook_name ||= begin
        hook = name.dup
        hook.downcase!
        hook.sub! /.*:/, ''
        hook
      end
    end

    def inherited(svc)
      Service::App.service(self)
      super
    end
  end

  # Public
  attr_reader :data

  # Public
  attr_reader :payload

  attr_writer :http
  attr_writer :secret_file
  attr_writer :secrets
  attr_writer :email_config_file
  attr_writer :email_config

  def initialize(data, payload)
    @data    = data
    @payload = payload
    @http    = nil
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
  def http_get(url = nil, params = nil, headers = nil)
    http.get do |req|
      req.url(url)                if url
      req.params.update(params)   if params
      req.headers.update(headers) if headers
      yield req if block_given?
    end
  end

  # Public
  def http_post(url = nil, body = nil, headers = nil)
    http.post do |req|
      req.url(url)                if url
      req.headers.update(headers) if headers
      req.body = body             if body
      yield req if block_given?
    end
  end

  # Public
  def http_method(method, url = nil, body = nil, headers = nil)
    http.send(method) do |req|
      req.url(url)                if url
      req.headers.update(headers) if headers
      req.body = body             if body
      yield req if block_given?
    end
  end

  def http(options = {})
    @http ||= begin
      options[:timeout] ||= 6
      Faraday.new(options) do |b|
        b.request :url_encoded
        b.adapter :net_http
      end
    end
  end

  # Public
  def secrets
    @secrets ||=
      File.exist?(secret_file) ? YAML.load_file(secret_file) : {}
  end

  # Public
  def email_config
    @email_config ||=
      File.exist?(email_config_file) ? YAML.load_file(email_config_file) : {}
  end

  def secret_file
    @secret_file ||= File.expand_path("../../config/secrets.yml", __FILE__)
  end

  def email_config_file
    @email_config_file ||= File.expand_path('../../config/email.yml', __FILE__)
  end

  def raise_config_error(msg = "Invalid configuration")
    raise ConfigurationError, msg
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

