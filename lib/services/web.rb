class Service::Web < Service
  include HttpHelper

  string :url,
    # adds a X-Hub-Signature of the body content
    # X-Hub-Signature: sha1=....
    :secret,

    # old hooks send form params ?payload=JSON(...)
    # new hooks should set content_type == 'json'
    :content_type,

    # 2 or 3
    :ssl_version

  white_list :url, :content_type, :ssl_version

  boolean :insecure_ssl # :(

  def receive_event
    http.headers['X-GitHub-Event'] = event.to_s

    if data['ssl_version'].to_i == 3
      http.ssl[:version] = :sslv3
    end

    deliver data['url'], :content_type => data['content_type'],
      :insecure_ssl => data['insecure_ssl'].to_i == 1, :secret => data['secret']
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

