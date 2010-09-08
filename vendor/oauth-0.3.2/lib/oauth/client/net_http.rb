require 'oauth/helper'
require 'oauth/client/helper'
require 'oauth/request_proxy/net_http'

class Net::HTTPRequest
  include OAuth::Helper

  attr_reader :oauth_helper

  def oauth!(http, consumer = nil, token = nil, options = {})
    options = { :request_uri      => oauth_full_request_uri(http),
                :consumer         => consumer,
                :token            => token,
                :scheme           => 'header',
                :signature_method => nil,
                :nonce            => nil,
                :timestamp        => nil }.merge(options)

    @oauth_helper = OAuth::Client::Helper.new(self, options)
    self.send("set_oauth_#{options[:scheme]}")
  end

  def signature_base_string(http, consumer = nil, token = nil, options = {})
    options = { :request_uri      => oauth_full_request_uri(http),
                :consumer         => consumer,
                :token            => token,
                :scheme           => 'header',
                :signature_method => nil,
                :nonce            => nil,
                :timestamp        => nil }.merge(options)

    OAuth::Client::Helper.new(self, options).signature_base_string
  end

private

  def oauth_full_request_uri(http)
    uri = URI.parse(self.path)
    uri.host = http.address
    uri.port = http.port

    if http.respond_to?(:use_ssl?) && http.use_ssl?
      uri.scheme = "https"
    else
      uri.scheme = "http"
    end

    uri.to_s
  end

  def set_oauth_header
    self['Authorization'] = @oauth_helper.header
  end

  # FIXME: if you're using a POST body and query string parameters, using this
  # method will convert those parameters on the query string into parameters in
  # the body. this is broken, and should be fixed.
  def set_oauth_body
    self.set_form_data(@oauth_helper.parameters_with_oauth)
    params_with_sig = @oauth_helper.parameters.merge(:oauth_signature => @oauth_helper.signature)
    self.set_form_data(params_with_sig)
  end

  def set_oauth_query_string
    oauth_params_str = @oauth_helper.oauth_parameters.map { |k,v| [escape(k), escape(v)] * "=" }.join("&")

    uri = URI.parse(path)
    if uri.query.to_s == ""
      uri.query = oauth_params_str
    else
      uri.query = uri.query + "&" + oauth_params_str
    end

    @path = uri.to_s

    @path << "&oauth_signature=#{escape(oauth_helper.signature)}"
  end
end
