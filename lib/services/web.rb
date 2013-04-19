class Service::Web < Service
  HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

  string :url,
    # adds a X-Hub-Signature of the body content
    # X-Hub-Signature: sha1=....
    :secret,

    # old hooks send form params ?payload=JSON(...)
    # new hooks should set content_type == 'json'
    :content_type

  white_list :url, :content_type

  boolean :insecure_ssl # :(

  def receive_event
    url = data['url'].to_s
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
    http.headers['X-GitHub-Event'] = event.to_s

    if data['insecure_ssl'].to_i == 1
      http.ssl[:verify] = false
    end

    body = if data['content_type'] == 'json'
      http.headers['content-type'] = 'application/json'
      generate_json(payload)
    else
      http.headers['content-type'] = 'application/x-www-form-urlencoded'
      Faraday::Utils.build_nested_query(
        http.params.merge(:payload => generate_json(payload)))
    end

    if !(secret = data['secret'].to_s).empty?
      http.headers['X-Hub-Signature'] =
        'sha1='+OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)
    end

    http_post url, body
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
end

