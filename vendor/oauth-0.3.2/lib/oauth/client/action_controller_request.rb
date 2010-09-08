require 'oauth/client/helper'
require 'oauth/request_proxy/action_controller_request'
require 'action_controller/test_process'

module ActionController
  class Base
    def process_with_oauth(request, response=nil)
      request.apply_oauth!
      process_without_oauth(request, response)
    end

    alias_method_chain :process, :oauth
  end

  class TestRequest
    def self.use_oauth=(bool)
      @use_oauth = bool
    end

    def self.use_oauth?
      @use_oauth
    end

    def configure_oauth(consumer = nil, token = nil, options = {})
      @oauth_options = { :consumer  => consumer,
                         :token     => token,
                         :scheme    => 'header',
                         :signature_method => nil,
                         :nonce     => nil,
                         :timestamp => nil }.merge(options)
    end

    def apply_oauth!
      return unless ActionController::TestRequest.use_oauth? && @oauth_options

      @oauth_helper = OAuth::Client::Helper.new(self, @oauth_options.merge(:request_uri => request_uri))

      self.send("set_oauth_#{@oauth_options[:scheme]}")
    end

    def set_oauth_header
      env['Authorization'] = @oauth_helper.header
    end

    def set_oauth_parameters
      @query_parameters = @oauth_helper.parameters_with_oauth
      @query_parameters.merge!(:oauth_signature => @oauth_helper.signature)
    end

    def set_oauth_query_string
    end
  end
end
