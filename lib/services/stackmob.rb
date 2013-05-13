class Service::Stackmob < Service
  string :token

  TOKEN_KEY = 'token'
  BASE_URL = "https://deploy.stackmob.com/callback"

  def receive_push
    token = data[TOKEN_KEY]
    raise_config_error "no token" if token.empty?

    http.url_prefix = BASE_URL
    http.headers['Content-Type'] = 'application/json'

    http_post token, generate_json(payload)
  end
end

