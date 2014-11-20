class Service::Web < Service
  include HttpHelper

  string :url,
    # old hooks send form params ?payload=JSON(...)
    # new hooks should set content_type == 'json'
    :content_type

  # adds a X-Hub-Signature of the body content
  # X-Hub-Signature: sha1=....
  password :secret

  white_list :url, :content_type

  boolean :insecure_ssl # :(

  def receive_event
    http.headers['X-GitHub-Event'] = event.to_s
    http.headers['X-GitHub-Delivery'] = delivery_guid.to_s

    res = deliver data['url'],
      :content_type => data['content_type'],
      :insecure_ssl => config_boolean_true?('insecure_ssl'),
      :secret => data['secret']

    if res.status < 200 || res.status > 299
      raise_config_error "Invalid HTTP Response: #{res.status}"
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
