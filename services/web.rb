class Service::Web < Service
  HMAC_DIGEST = OpenSSL::Digest::Digest.new('sha1')

  string :url,
    # adds a X-Hub-Signature of the body content
    # X-Hub-Signature: sha1=....
    :secret, 

    # old hooks send form params ?payload=JSON(...)
    # new hooks should set content_type == 'json'
    :content_type

  def receive_push
    http.url_prefix = data['url']

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

    http_post '', body
  end
end

