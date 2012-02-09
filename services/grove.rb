class Service::Grove < Service
  string :channel_token

  def receive_push
    raise_config_error "Missing channel token" if data['channel_token'].to_s.empty?

    token = data['channel_token'].to_s
    
    res = http_post "https://grove.io/api/services/github/#{token}", 
      :payload => JSON.generate(payload)
  end
end
