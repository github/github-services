class Service::Gemini < Service
  string :server_url, :api_key

  def receive_push
    if data['server_url'].to_s.empty?
      raise_config_error "Server URL is missing"
    end

    if data['api_key'].to_s.empty?
      raise_config_error "API Key is missing"
    end

    # Sets this basic auth info for every request. GitHub user and Gemini API Key.
    http.basic_auth(data['api_key'], data['api_key'])

    # Every request sends JSON.
    http.headers['Content-Type'] = 'application/json'

    # Uses this URL as a prefix for every request.
    http.url_prefix = '%s/api/github' % [data['server_url']]

    # POST http://localhost/gemini/api/github/commit
    http_post "commit", generate_json(payload)
  end
end
