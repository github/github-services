class Service::Gemnasium < Service
  string :user, :token

  def receive_push
    http.basic_auth(user, signature)
    http_post(url, body, headers)
  end

  def http(*)
    super.tap{|h| h.builder.delete(Faraday::Request::UrlEncoded) }
  end

  def user
    data["user"].strip
  end

  def signature
    Digest::SHA2.hexdigest(token + body)
  end

  def token
    data["token"].strip.downcase
  end

  def body
    payload.to_json
  end

  def url
    "https://gemnasium.com/repositories/hook"
  end

  def headers
    {:content_type => "application/json"}
  end
end
