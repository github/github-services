class Service::Web < Service
  HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

  string :url,
    # adds a X-Hub-Signature of the body content
    # X-Hub-Signature: sha1=....
    :secret, 

    # old hooks send form params ?payload=JSON(...)
    # new hooks should set content_type == 'json'
    :content_type

  boolean :insecure_ssl # :(

  def receive_event
    # set this so that basic auth is added,
    # and GET params are added to the POST body
    http.url_prefix = data['url']
    http.headers['X-GitHub-Event'] = @event.to_s

    if data['insecure_ssl'].to_i == 1
      http.ssl[:verify] = false
    end

    body = if data['content_type'] == 'json'
      http.headers['content-type'] = 'application/json'
      JSON.generate(payload)
    else
      http.headers['content-type'] = 'application/x-www-form-urlencoded'
      Faraday::Utils.build_nested_query(
        http.params.merge(:payload => JSON.generate(payload)))
    end

    if !(secret = data['secret'].to_s).empty?
      http.headers['X-Hub-Signature'] =
        'sha1='+OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, body)
    end

    http_post data['url'], body
  end
end

