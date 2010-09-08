require 'oauth/client'
require 'oauth/consumer'
require 'oauth/helper'
require 'oauth/token'
require 'oauth/signature/hmac/sha1'

module OAuth::Client
  class Helper
    include OAuth::Helper

    def initialize(request, options = {})
      @request = request
      @options = options
      @options[:signature_method] ||= 'HMAC-SHA1'
    end

    def options
      @options
    end

    def nonce
      options[:nonce] ||= generate_key
    end

    def timestamp
      options[:timestamp] ||= generate_timestamp
    end

    def oauth_parameters
      {
        'oauth_consumer_key'     => options[:consumer].key,
        'oauth_token'            => options[:token] ? options[:token].token : '',
        'oauth_signature_method' => options[:signature_method],
        'oauth_timestamp'        => timestamp,
        'oauth_nonce'            => nonce,
        'oauth_version'          => '1.0'
      }.reject { |k,v| v.to_s == "" }
    end

    def signature(extra_options = {})
      OAuth::Signature.sign(@request, { :uri      => options[:request_uri],
                                        :consumer => options[:consumer],
                                        :token    => options[:token] }.merge(extra_options) )
    end

    def signature_base_string(extra_options = {})
      OAuth::Signature.signature_base_string(@request, { :uri        => options[:request_uri],
                                                         :consumer   => options[:consumer],
                                                         :token      => options[:token],
                                                         :parameters => oauth_parameters}.merge(extra_options) )
    end

    def header
      parameters = oauth_parameters
      parameters.merge!('oauth_signature' => signature(options.merge(:parameters => parameters)))

      header_params_str = parameters.map { |k,v| "#{k}=\"#{escape(v)}\"" }.join(', ')

      realm = "realm=\"#{options[:realm]}\", " if options[:realm]
      "OAuth #{realm}#{header_params_str}"
    end

    def parameters
      OAuth::RequestProxy.proxy(@request).parameters
    end

    def parameters_with_oauth
      oauth_parameters.merge(parameters)
    end
  end
end
