class Service::Web < Service
  include HttpHelper

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
    url = set_url(data['url'])

    http.headers['X-GitHub-Event'] = event.to_s

    if data['insecure_ssl'].to_i == 1
      http.ssl[:verify] = false
    end

    body = encode_body(data['content_type'])

    set_body_signature(body, data['secret'])

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

  def original_body
    payload
  end

  def default_encode_body
    encode_body_as_form
  end
end

