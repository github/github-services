class Service::Trac < Service
  string :url
  password :token
  white_list :url

  def receive_push
    http.ssl[:verify] = false
    http.url_prefix = data['url']
    http_post "github/#{data['token']}", :payload => generate_json(payload)
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused. Invalid server URL."
  end
end
