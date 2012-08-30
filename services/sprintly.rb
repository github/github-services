class Service::Sprintly < Service
  def receive_push
    if data['api_key'].to_s.empty?
      raise_config_error "Must provide an api key"
    end

    if data['username'].to_s.empty?
      raise_config_error "Must provide a sprint.ly username"
    end

    # @@@ Auth? username + api_key?
    http.basic_auth(data['username'], data['api_key'])

    http.headers['Content-Type'] = 'application/json'
    http.url_prefix = "https://sprint.ly/integration/github/" # @@@
    
    payload['commits'].each do |commit|
      # POST https://url_prefix/api_key?
      http_post data['api_key'], commit.to_json
    end
  end
end

