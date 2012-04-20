class Service::Grove < Service
  string :channel_token

  def receive_push
    token = data['channel_token'].to_s
    raise_config_error "Missing channel token" if token.empty?

    res = http_post "https://grove.io/api/services/github/#{token}", 
      :payload => JSON.generate(payload)
  end
end
