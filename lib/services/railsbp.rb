class Service::Railsbp < Service
  string :railsbp_url, :token
  white_list :railsbp_url

  def receive_push
    http_post railsbp_url, :token => token, :payload => generate_json(payload)
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
