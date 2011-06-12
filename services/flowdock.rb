class Service::Flowdock < Service
  def receive_push
    raise_config_error "Missing token" if data['token'].to_s.empty?

    http_post "https://api.flowdock.com/v1/git",
      :token => data['token'],
      :payload => JSON.generate(payload)
  end
end
