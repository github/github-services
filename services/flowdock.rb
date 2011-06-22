class Service::Flowdock < Service
  string :token

  def receive_push
    raise_config_error "Missing token" if data['token'].to_s.empty?

    # :(
    http.ssl[:verify] = false

    http_post "https://api.flowdock.com/v1/git",
      :token => data['token'],
      :payload => JSON.generate(payload)
  end
end
