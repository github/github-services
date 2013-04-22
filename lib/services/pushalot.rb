class Service::Pushalot < Service
  string :authorization_token

  url "https://pushalot.com"
  logo_url "https://pushalot.com/content/images/favicon.png"
  maintained_by :github => 'molesinski'
  supported_by :web => 'https://pushalot.com/support'

  def receive_push
    res = http_post "https://pushalot.com/api/githubhook",
      :authorizationToken => authorization_token,
      :payload => generate_json(payload)

    if res.status != 200
      raise_config_error
    end
  end

  def authorization_token
    data["authorization_token"].to_s.strip
  end
end

