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
    wrap_http_errors do
      url = set_url(data['url'])

      http.headers['X-GitHub-Event'] = event.to_s

      if data['insecure_ssl'].to_i == 1
        http.ssl[:verify] = false
      end

      body = encode_body(data['content_type'])

      set_body_signature(body, data['secret'])

      http_post url, body
    end
  end

  def original_body
    payload
  end

  def default_encode_body
    encode_body_as_form
  end

  def encode_body_as_form
    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    Faraday::Utils.build_nested_query(
      http.params.merge(:payload => generate_json(original_body)))
  end
end

