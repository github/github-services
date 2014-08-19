class Service::NHook < Service
  string :apiKey

  url 'http://www.nhook.net'
  logo_url 'http://nhook.net/content/images/logo.png'

  default_events :push

  maintained_by :github => 'aquiladev',
    :twitter => '@aquiladev'

  supported_by  :email => 'aquila@uneta.org',
    :github => 'aquiladev',
    :twitter => '@aquiladev'

  def receive_push
    apiKey = data['api_key']
    raise_config_error 'Missing ApiKey' if apiKey.to_s.empty?

    url = "http://nhapis.azurewebsites.net/github/#{apiKey}"
    http.headers['Content-Type'] = 'application/json'
    http_post url, generate_json(payload)
  end
end