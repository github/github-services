class Service
  module HttpHelper
    HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

    def deliver_event_payload
      wrap_http_errors do
        url = set_url(data['url'])

        if data['insecure_ssl'].to_i == 1
          http.ssl[:verify] = false
        end

        body = encode_body(data['content_type'])

        set_body_signature(body, data['secret'])

        http_post url, body
      end
    end

    def wrap_http_errors
      yield
    rescue Addressable::URI::InvalidURIError, Errno::EHOSTUNREACH
      raise_missing_error $!.to_s
    rescue SocketError
      if $!.to_s =~ /getaddrinfo:/
        raise_missing_error "Invalid host name."
      else
        raise
      end
    rescue EOFError
      raise_config_error "Invalid server response. Make sure the URL uses the correct protocol."
    end

    def set_url(url)
      url = url.to_s
      url.gsub! /\s/, ''

      if url.empty?
        raise_config_error "Invalid URL: #{url.inspect}"
      end

      if url !~ /^https?\:\/\//
        url = "http://#{url}"
      end

      # set this so that basic auth is added,
      # and GET params are added to the POST body
      http.url_prefix = url

      url
    end

    def set_body_signature(body, secret)
      return if (secret = secret.to_s).empty?
      http.headers['X-Hub-Signature'] =
        'sha1='+OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)
    end

    def original_body
      {:payload => payload, :event => event.to_s, :config => data}
    end

    def encode_body(content_type = nil)
      method = "encode_body_as_#{content_type}"
      respond_to?(method) ? send(method) : default_encode_body
    end

    def default_encode_body
      encode_body_as_json
    end

    def encode_body_as_json
      http.headers['content-type'] = 'application/json'
      generate_json(original_body)
    end
  end
end
