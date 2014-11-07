class Service::Gemnasium < Service
  string :user
  password :token
  white_list :user

  def receive_push
    http.basic_auth(user, signature)
    http_post(url, body, headers)
  end

  def http(*)
    super.tap{|h| h.builder.delete(Faraday::Request::UrlEncoded) }
  end

  def user
    data["user"].strip
  rescue
    raise_config_error "Invalid user value"
  end

  def signature
    Digest::SHA2.hexdigest(token + body)
  end

  def token
    data["token"].strip.downcase
  rescue
    raise_config_error "Invalid token value"
  end

  def body
    generate_json(payload)
  end

  def url
    "https://gemnasium.com/repositories/hook"
  end

  def headers
    {:content_type => "application/json"}
  end
end
