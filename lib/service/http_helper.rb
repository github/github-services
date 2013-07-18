class Service
  module HttpHelper
    HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

    def deliver(url_value, options = {})
      insecure = options[:insecure_ssl]
      ctype = options[:content_type]
      secret = options[:secret]

      wrap_http_errors do
        url = set_url(url_value)

        if insecure
          http.ssl[:verify] = false
        end

        body = encode_body(ctype)

        set_body_signature(body, secret)

        http_post url, body
      end
    end

    # Grabs a sanitized configuration value.
    def config_value(key)
      value = data[key.to_s].to_s
      value.strip!
      value
    end

    # Grabs a sanitized configuration value and ensures it is set.
    def required_config_value(key)
      if (value = config_value(key)).empty?
        raise_config_error("#{key.inspect} is empty")
      end

      value
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
      raise NotImplementedError
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
