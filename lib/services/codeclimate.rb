class Service::CodeClimate < Service
  string :token

  def receive_push
    http.ssl[:verify] = false
    http.basic_auth "github", token
    http_post "https://codeclimate.com/github_pushes", :payload => generate_json(payload)
  end

  def token
    data["token"].to_s.strip
  end

end
