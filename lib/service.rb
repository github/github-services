require 'faraday'

module PayloadHelpers
  def created?
    payload['created'] or !!(payload['before'] =~ /0{40}/)
  end

  def deleted?
    payload['deleted'] or !!(payload['after'] =~ /0{40}/)
  end

  def forced?
    payload['forced']
  end

  def ref
    payload['ref']
  end

  def base_ref
    payload['base_ref']
  end

  def tag?
    !!(ref =~ %r|^refs/tags/|)
  end

  def ref_name
    payload['ref_name'] ||= ref.sub(/\Arefs\/(heads|tags)\//, '')
  end
  alias :tag_name :ref_name
  alias :branch_name :ref_name

  def base_ref_name
    payload['base_ref_name'] ||= base_ref.sub(/\Arefs\/(heads|tags)\//, '')
  end

  def before_sha
    payload['before'][0..6]
  end

  def after_sha
    payload['after'][0..6]
  end

  def format_commit_message(commit)
    short = commit['message'].split("\n", 2).first
    short += '...' if short != commit['message']
    "[#{repo_name}/#{branch_name}] #{short} - #{commit['author']['name']}"
  end

  def commit_messages
    distinct_commits.map do |commit|
      format_commit_message(commit)
    end
  end

  def summary_message
    message = []
    message << "[#{repo_name}] #{pusher_name}"

    if created?
      if tag?
        message << "tagged #{tag_name} at"
        message << (base_ref ? base_ref_name : after_sha)
      else
        message << "created #{branch_name}"

        if base_ref
          message << "from #{base_ref_name}"
        elsif distinct_commits.empty?
          message << "at #{after_sha}"
        end

        if distinct_commits.any?
          num = distinct_commits.size
          message << "(+#{num} new commit#{num > 1 ? 's' : ''})"
        end
      end

    elsif deleted?
      message << "deleted #{branch_name} at #{before_sha}"

    elsif forced?
      message << "force-pushed #{branch_name} from #{before_sha} to #{after_sha}"

    elsif commits.any? and distinct_commits.empty?
      if base_ref
        message << "merged #{base_ref_name} into #{branch_name}"
      else
        message << "fast-forwarded #{branch_name} from #{before_sha} to #{after_sha}"
      end

    elsif distinct_commits.any?
      num = distinct_commits.size
      message << "pushed #{num} new commit#{num > 1 ? 's' : ''} to #{branch_name}"

    else
      message << "pushed nothing"
    end

    message.join(' ')
  end

  def summary_url
    if created?
      if distinct_commits.empty?
        branch_url
      else
        compare_url
      end

    elsif deleted?
      before_sha_url

    elsif forced?
      branch_url

    elsif distinct_commits.size == 1
      distinct_commits.first['url']

    else
      compare_url
    end
  end

  def repo_url
    payload['repository']['url']
  end

  def compare_url
    payload['compare']
  end

  def branch_url
    repo_url + "/commits/#{branch_name}"
  end

  def before_sha_url
    repo_url + "/commit/#{before_sha}"
  end

  def after_sha_url
    repo_url + "/commit/#{after_sha}"
  end

  def pusher_name
    payload['pusher']['name']
  end

  def owner_name
    payload['repository']['owner']['name']
  end

  def repo_name
    payload['repository']['name']
  end

  def name_with_owner
    File.join(owner_name, repo_name)
  end

  def commits
    payload['commits']
  end

  def distinct_commits
    payload['distinct_commits'] ||= commits.select do |commit|
      commit['distinct'] and !commit['message'].to_s.strip.empty?
    end
  end
end

class Service
  include PayloadHelpers

  class << self
    attr_reader :hook_name

    def hook_name=(value)
      @hook_name = value.to_s.gsub(/[^a-z]/, '')
      Service::App.service(self)
    end

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
  end

  attr_reader :data
  attr_reader :payload

  attr_writer :http
  attr_writer :secret_file
  attr_writer :secrets
  attr_writer :email_config_file
  attr_writer :email_config

  def initialize(data, payload)
    @data       = data
    @payload    = payload
    @http = nil
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

  def secrets
    @secrets ||=
      File.exist?(secret_file) ? YAML.load_file(secret_file) : {}
  end

  def secret_file
    @secret_file ||= File.expand_path("../../config/secrets.yml", __FILE__)
  end

  def email_config
    @email_config ||=
      File.exist?(email_config_file) ? YAML.load_file(email_config_file) : {}
  end

  def email_config_file
    @email_config_file ||= File.expand_path('../../config/email.yml', __FILE__)
  end

  def raise_config_error(msg = "Invalid configuration")
    raise ConfigurationError, msg
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
