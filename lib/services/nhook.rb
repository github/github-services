class Service::NHook < Service::HttpPost
  string :apiKey

  url 'http://www.nhook.net'
  logo_url 'http://nhook.net/content/images/logo.png'

  default_events :push

  maintained_by :github => 'aquiladev',
    :twitter => '@aquiladev'

  supported_by  :email => 'aquila@uneta.org',
    :github => 'aquiladev',
    :twitter => '@aquiladev'

  def receive_event
    apiKey = data['api_key']
    raise_config_error 'Missing ApiKey' if apiKey.to_s.empty?

    url = "http://api.nhook.net/github/#{apiKey}"
    deliver url
  end
end