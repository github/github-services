require 'oauth/request_proxy/base'
require 'net/http'
require 'uri'
require 'cgi'

module OAuth::RequestProxy::Net
  module HTTP
    class HTTPRequest < OAuth::RequestProxy::Base
      proxies ::Net::HTTPRequest

      def method
        request.method
      end

      def uri
        uri = options[:uri]
        uri.to_s
      end

      def parameters
        if options[:clobber_request]
          options[:parameters]
        else
          all_parameters
        end
      end

    private

      def all_parameters
        request_params = CGI.parse(query_string)
        if options[:parameters]
          options[:parameters].each do |k,v|
            if request_params.has_key?(k)
              request_params[k] << v
            else
              request_params[k] = [v].flatten
            end
          end
        end
        request_params
      end

      def query_string
        params = [ query_params, auth_header_params ]
        is_form_urlencoded = request['Content-Type'] != nil && request['Content-Type'].downcase == 'application/x-www-form-urlencoded'
        params << post_params if method.to_s.upcase == 'POST' && is_form_urlencoded
        params.compact.join('&')
      end

      def query_params
        URI.parse(request.path).query
      end

      def post_params
        request.body
      end

      def auth_header_params
        return nil unless request['Authorization'] && request['Authorization'][0,5] == 'OAuth'
        auth_params = request['Authorization']
      end
    end
  end
end
