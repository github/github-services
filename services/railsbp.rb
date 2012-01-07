class Service::Railsbp < Service
  string :railsbp_url, :token

  def receive_push
    http_post railsbp_url, :token => token, :payload => payload.to_json
  end

  def railsbp_url
    data["railsbp_url"].try(:strip) || "https://railsbp.com"
  end

  def token
    data['token'].strip
  end
end
