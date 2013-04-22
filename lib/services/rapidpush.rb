class Service::RapidPush < Service
  string :apikey

  def receive_push
    http.ssl[:verify] = false
    http_post "https://rapidpush.net/api/github/#{apikey}", :payload => generate_json(payload)
  end

  def apikey
    data["apikey"].to_s.strip
  end
end
