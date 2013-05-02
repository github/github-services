class Service
  module HttpHelper
    HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

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
