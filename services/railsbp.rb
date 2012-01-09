class Service::Railsbp < Service
  string :railsbp_url, :token

  def receive_push
    http_post railsbp_url, :token => token, :payload => payload.to_json
  end

  def railsbp_url
    if !(url = data["railsbp_url"].to_s).empty?
      url.strip
    else
      "https://railsbp.com"
    end
  end

  def token
    data['token'].strip
  end
end
