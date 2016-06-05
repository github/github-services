class Service::NHook < Service
  string :api_key

  url 'http://www.nhook.net'
  logo_url 'http://nhook.net/content/images/logo.png'

  default_events :push

  maintained_by :github => 'aquiladev',
    :twitter => '@aquiladev'

  supported_by  :email => 'aquila@uneta.org',
    :github => 'aquiladev',
    :twitter => '@aquiladev'

  def receive_push
    api_key = data['api_key']
    raise_config_error 'Missing ApiKey' if api_key.to_s.empty?

    url = "http://nhapis.azurewebsites.net/github/#{api_key}"
    http.headers['Content-Type'] = 'application/json'
    http_post url, generate_json(payload)
  end
end